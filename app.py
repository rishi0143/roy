
import os
import re
import uuid
import hmac

from datetime import date
from decimal import Decimal

from flask import (
    Flask,
    render_template,
    request,
    jsonify,
    session,
    redirect,
    url_for
)

from database import get_db_connection


app = Flask(__name__)

app.secret_key = os.environ["SECRET_KEY"]

app.config.update(
    SESSION_COOKIE_HTTPONLY=True,
    SESSION_COOKIE_SAMESITE="Lax",
    SESSION_COOKIE_SECURE=os.getenv("COOKIE_SECURE", "false").lower() == "true",
    PERMANENT_SESSION_LIFETIME=1800
)


# ---------------- HOME PAGE ----------------

@app.route("/")
def home():
    return render_template("index.html")


# ---------------- LOCATIONS API ----------------

@app.route("/api/locations")
def locations():
    return jsonify({
        "sources": ["Hyderabad", "Vizag", "Vizianagaram"],
        "destinations": ["Chennai", "Palasa", "Sompeta"]
    })


# ---------------- BUS SEARCH API ----------------

@app.route("/api/search")
def search_buses():

    source = request.args.get("source", "").strip()
    destination = request.args.get("destination", "").strip()
    travel_date = request.args.get("date", "").strip()

    if not source or not destination or not travel_date:
        return jsonify({
            "error": "Please select source, destination and date"
        }), 400

    try:
        date.fromisoformat(travel_date)
    except ValueError:
        return jsonify({"error": "Invalid travel date"}), 400

    if source not in ["Hyderabad", "Vizag", "Vizianagaram"]:
        return jsonify({"error": "Invalid source"}), 400

    if destination not in ["Chennai", "Palasa", "Sompeta"]:
        return jsonify({"error": "Invalid destination"}), 400

    if source == destination:
        return jsonify({"error": "Source and destination cannot be same"}), 400

    conn = None
    cursor = None

    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)

        cursor.execute("""
            SELECT
                t.trip_id,
                b.bus_name,
                b.bus_type,
                t.source,
                t.destination,
                t.departure_time,
                t.arrival_time,
                t.fare,
                t.available_seats
            FROM trips t
            JOIN buses b ON t.bus_id = b.bus_id
            WHERE t.source = %s
              AND t.destination = %s
              AND DATE(t.departure_time) = %s
              AND t.available_seats > 0
            ORDER BY t.departure_time
        """, (source, destination, travel_date))

        buses = cursor.fetchall()

        for bus in buses:
            bus["departure_time"] = bus["departure_time"].strftime(
                "%Y-%m-%d %H:%M"
            )
            bus["arrival_time"] = bus["arrival_time"].strftime(
                "%Y-%m-%d %H:%M"
            )
            bus["fare"] = float(bus["fare"])

        return jsonify(buses)

    except Exception:
        app.logger.exception("Bus search failed")
        return jsonify({
            "error": "Unable to search buses. Check database connection."
        }), 500

    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()


# ---------------- BOOK TICKET API ----------------

@app.route("/api/book", methods=["POST"])
def book_ticket():

    data = request.get_json(silent=True) or {}

    try:
        trip_id = int(data.get("trip_id"))
        seats = int(data.get("seats"))
        name = str(data.get("name", "")).strip()
        age = int(data.get("age"))
        gender = str(data.get("gender", "")).strip()
        phone = str(data.get("phone", "")).strip()
        email = str(data.get("email", "")).strip()

        if trip_id <= 0 or seats < 1 or seats > 6:
            return jsonify({
                "error": "Select between 1 and 6 seats"
            }), 400

        if not name or len(name) > 100:
            return jsonify({
                "error": "Enter a valid passenger name"
            }), 400

        if age < 1 or age > 120:
            return jsonify({
                "error": "Enter a valid age"
            }), 400

        if not re.fullmatch(r"[0-9]{10,15}", phone):
            return jsonify({
                "error": "Enter a valid phone number (10-15 digits)"
            }), 400

        if gender not in ("Male", "Female", "Other"):
            return jsonify({
                "error": "Select a valid gender"
            }), 400

        if email and (
            len(email) > 150 or
            not re.fullmatch(r"[^@\s]+@[^@\s]+\.[^@\s]+", email)
        ):
            return jsonify({
                "error": "Enter a valid email address"
            }), 400

    except (ValueError, TypeError):
        return jsonify({
            "error": "Invalid booking details"
        }), 400

    conn = None
    cursor = None

    try:
        conn = get_db_connection()
        conn.start_transaction()

        cursor = conn.cursor(dictionary=True)

        cursor.execute("""
            SELECT trip_id, fare, available_seats
            FROM trips
            WHERE trip_id = %s
            FOR UPDATE
        """, (trip_id,))

        trip = cursor.fetchone()

        if not trip:
            conn.rollback()
            return jsonify({
                "error": "Bus trip not found"
            }), 404

        if trip["available_seats"] < seats:
            conn.rollback()
            return jsonify({
                "error": "Not enough seats available"
            }), 400

        total = Decimal(str(trip["fare"])) * seats

        cursor.execute("""
            INSERT INTO passengers
            (full_name, age, gender, phone, email)
            VALUES (%s, %s, %s, %s, %s)
        """, (name, age, gender, phone, email or None))

        passenger_id = cursor.lastrowid

        booking_reference = "BUS-" + uuid.uuid4().hex[:10].upper()

        cursor.execute("""
            INSERT INTO bookings
            (
                booking_reference,
                passenger_id,
                trip_id,
                seats_booked,
                total_amount
            )
            VALUES (%s, %s, %s, %s, %s)
        """, (
            booking_reference,
            passenger_id,
            trip_id,
            seats,
            total
        ))

        cursor.execute("""
            UPDATE trips
            SET available_seats = available_seats - %s
            WHERE trip_id = %s
        """, (seats, trip_id))

        conn.commit()

        return jsonify({
            "message": "Booking confirmed",
            "booking_reference": booking_reference,
            "seats": seats,
            "total_amount": float(total)
        }), 201

    except Exception:
        if conn:
            conn.rollback()

        app.logger.exception("Booking failed")

        return jsonify({
            "error": "Booking failed. Please try again."
        }), 500

    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()


# ---------------- BOOKING DETAILS API ----------------

@app.route("/api/booking/<reference>")
def get_booking(reference):

    conn = None
    cursor = None

    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)

        cursor.execute("""
            SELECT
                bk.booking_reference,
                bk.seats_booked,
                bk.total_amount,
                bk.booking_status,
                bk.booked_at,
                p.full_name,
                p.phone,
                t.source,
                t.destination,
                t.departure_time,
                b.bus_name,
                b.bus_type
            FROM bookings bk
            JOIN passengers p
                ON bk.passenger_id = p.passenger_id
            JOIN trips t
                ON bk.trip_id = t.trip_id
            JOIN buses b
                ON t.bus_id = b.bus_id
            WHERE bk.booking_reference = %s
        """, (reference.strip().upper(),))

        booking = cursor.fetchone()

        if not booking:
            return jsonify({
                "error": "Booking not found"
            }), 404

        booking["total_amount"] = float(booking["total_amount"])
        booking["departure_time"] = booking[
            "departure_time"
        ].strftime("%Y-%m-%d %H:%M")

        booking["booked_at"] = booking[
            "booked_at"
        ].strftime("%Y-%m-%d %H:%M")

        return jsonify(booking)

    except Exception:
        app.logger.exception("Booking lookup failed")

        return jsonify({
            "error": "Unable to retrieve booking"
        }), 500

    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()


# ---------------- OWNER LOGIN ----------------

@app.route("/owner/login", methods=["GET", "POST"])
def owner_login():

    if session.get("owner_logged_in"):
        return redirect(url_for("owner_dashboard"))

    if request.method == "POST":

        username = request.form.get("username", "")
        password = request.form.get("password", "")

        expected_user = os.environ["ADMIN_USERNAME"]
        expected_password = os.environ["ADMIN_PASSWORD"]

        valid_user = hmac.compare_digest(
            username, expected_user
        )

        valid_password = hmac.compare_digest(
            password, expected_password
        )

        if valid_user and valid_password:
            session.clear()
            session["owner_logged_in"] = True
            session.permanent = True

            return redirect(url_for("owner_dashboard"))

        return render_template(
            "owner_login.html",
            error="Invalid username or password"
        ), 401

    return render_template("owner_login.html")


# ---------------- OWNER DASHBOARD ----------------

@app.route("/owner/dashboard")
def owner_dashboard():

    if not session.get("owner_logged_in"):
        return redirect(url_for("owner_login"))

    conn = None
    cursor = None

    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)

        cursor.execute("""
            SELECT
                bk.booking_reference,
                bk.seats_booked,
                bk.total_amount,
                bk.booking_status,
                bk.booked_at,
                p.full_name,
                p.age,
                p.gender,
                p.phone,
                p.email,
                t.source,
                t.destination,
                t.departure_time,
                b.bus_name,
                b.bus_type
            FROM bookings bk
            JOIN passengers p
                ON bk.passenger_id = p.passenger_id
            JOIN trips t
                ON bk.trip_id = t.trip_id
            JOIN buses b
                ON t.bus_id = b.bus_id
            ORDER BY bk.booked_at DESC
        """)

        bookings = cursor.fetchall()

        total_bookings = len(bookings)

        total_revenue = sum(
            (
                Decimal(str(b["total_amount"]))
                for b in bookings
                if b["booking_status"] == "CONFIRMED"
            ),
            Decimal("0.00")
        )

        for booking in bookings:
            booking["total_amount"] = float(
                booking["total_amount"]
            )

            booking["departure_time"] = booking[
                "departure_time"
            ].strftime("%Y-%m-%d %H:%M")

            booking["booked_at"] = booking[
                "booked_at"
            ].strftime("%Y-%m-%d %H:%M")

        return render_template(
            "owner_dashboard.html",
            bookings=bookings,
            total_bookings=total_bookings,
            total_revenue=float(total_revenue)
        )

    except Exception:
        app.logger.exception("Owner dashboard failed")
        return "Unable to load dashboard. Check database connection.", 500

    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()


# ---------------- OWNER LOGOUT ----------------

@app.route("/owner/logout")
def owner_logout():

    session.clear()

    return redirect(url_for("owner_login"))


# ---------------- APPLICATION START ----------------

if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=5000,
        debug=False
    )
