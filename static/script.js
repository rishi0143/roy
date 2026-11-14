const sourceSelect = document.getElementById("source");
const destinationSelect = document.getElementById("destination");
const travelDate = document.getElementById("travelDate");
const searchForm = document.getElementById("searchForm");
const busResults = document.getElementById("busResults");
const message = document.getElementById("message");

const bookingSection = document.getElementById("bookingSection");
const bookingForm = document.getElementById("bookingForm");
const bookingMessage = document.getElementById("bookingMessage");

const lookupForm = document.getElementById("lookupForm");
const bookingDetails = document.getElementById("bookingDetails");


// Set minimum travel date to today
const today = new Date();
const localToday = [
    today.getFullYear(),
    String(today.getMonth() + 1).padStart(2, "0"),
    String(today.getDate()).padStart(2, "0")
].join("-");

travelDate.min = localToday;


// Load locations
async function loadLocations() {
    try {
        const response = await fetch("/api/locations");
        const data = await response.json();

        data.sources.forEach(location => {
            const option = document.createElement("option");
            option.value = location;
            option.textContent = location;
            sourceSelect.appendChild(option);
        });

        data.destinations.forEach(location => {
            const option = document.createElement("option");
            option.value = location;
            option.textContent = location;
            destinationSelect.appendChild(option);
        });

    } catch (error) {
        message.textContent = "Unable to load locations.";
    }
}


// Search buses
searchForm.addEventListener("submit", async function(event) {
    event.preventDefault();

    busResults.innerHTML = "";
    message.textContent = "Searching buses...";

    const source = sourceSelect.value;
    const destination = destinationSelect.value;
    const date = travelDate.value;

    if (source === destination) {
        message.textContent = "Source and destination must be different.";
        return;
    }

    try {
        const params = new URLSearchParams({
            source: source,
            destination: destination,
            date: date
        });

        const response = await fetch(`/api/search?${params}`);
        const data = await response.json();

        if (!response.ok) {
            throw new Error(data.error || "Search failed.");
        }

        if (data.length === 0) {
            message.textContent = "No buses found for this route and date.";
            return;
        }

        message.textContent = `${data.length} bus(es) found.`;

        data.forEach(bus => {
            const card = document.createElement("div");
            card.className = "bus-card";

            const heading = document.createElement("h3");
            heading.textContent = bus.bus_name;

            const details = document.createElement("div");

            [
                `Type: ${bus.bus_type}`,
                `Route: ${bus.source} → ${bus.destination}`,
                `Departure: ${bus.departure_time}`,
                `Arrival: ${bus.arrival_time}`,
                `Available seats: ${bus.available_seats}`
            ].forEach(line => {
                const p = document.createElement("p");
                p.textContent = line;
                details.appendChild(p);
            });

            const fare = document.createElement("p");
            fare.className = "fare";
            fare.textContent = `₹${bus.fare.toFixed(2)}`;

            const button = document.createElement("button");
            button.className = "primary-button";
            button.textContent = "Book Now";
            button.addEventListener("click", () => openBooking(bus));

            card.append(heading, details, fare, button);
            busResults.appendChild(card);
        });

    } catch (error) {
        message.textContent = error.message;
    }
});


// Open booking form
function openBooking(bus) {
    document.getElementById("tripId").value = bus.trip_id;

    const seatsInput = document.getElementById("seats");
    seatsInput.value = 1;
    seatsInput.max = Math.min(6, bus.available_seats);

    bookingMessage.textContent = "";
    bookingSection.classList.remove("hidden");
    bookingSection.scrollIntoView({ behavior: "smooth" });
}


// Cancel booking form
document.getElementById("cancelBooking").addEventListener("click", () => {
    bookingSection.classList.add("hidden");
    bookingForm.reset();
});


// Confirm booking
bookingForm.addEventListener("submit", async function(event) {
    event.preventDefault();

    bookingMessage.textContent = "Processing booking...";

    const bookingData = {
        trip_id: document.getElementById("tripId").value,
        name: document.getElementById("passengerName").value.trim(),
        age: document.getElementById("age").value,
        gender: document.getElementById("gender").value,
        phone: document.getElementById("phone").value.trim(),
        email: document.getElementById("email").value.trim(),
        seats: document.getElementById("seats").value
    };

    try {
        const response = await fetch("/api/book", {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify(bookingData)
        });

        const data = await response.json();

        if (!response.ok) {
            throw new Error(data.error || "Booking failed.");
        }

        bookingMessage.textContent =
            `Booking confirmed! Reference: ${data.booking_reference}. ` +
            `Seats: ${data.seats}. Total: ₹${data.total_amount.toFixed(2)}`;

        document.getElementById("bookingReference").value =
            data.booking_reference;

        bookingForm.reset();
        bookingSection.classList.add("hidden");

        // Refresh search results to show updated seat availability
        searchForm.dispatchEvent(new Event("submit", { cancelable: true }));

    } catch (error) {
        bookingMessage.textContent = error.message;
    }
});


// Find booking
lookupForm.addEventListener("submit", async function(event) {
    event.preventDefault();

    bookingDetails.textContent = "Looking up booking...";

    const reference = document.getElementById("bookingReference")
        .value.trim();

    try {
        const response = await fetch(
            `/api/booking/${encodeURIComponent(reference)}`
        );

        const data = await response.json();

        if (!response.ok) {
            throw new Error(data.error || "Booking not found.");
        }

        const card = document.createElement("div");
        card.className = "booking-card";

        const heading = document.createElement("h3");
        heading.textContent = "Booking Confirmed";

        const lines = [
            `Booking Reference: ${data.booking_reference}`,
            `Passenger: ${data.full_name}`,
            `Phone: ${data.phone}`,
            `Bus: ${data.bus_name} (${data.bus_type})`,
            `Route: ${data.source} → ${data.destination}`,
            `Departure: ${data.departure_time}`,
            `Seats: ${data.seats_booked}`,
            `Total Amount: ₹${data.total_amount.toFixed(2)}`,
            `Status: ${data.booking_status}`,
            `Booked At: ${data.booked_at}`
        ];

        card.appendChild(heading);

        lines.forEach(line => {
            const p = document.createElement("p");
            p.textContent = line;
            card.appendChild(p);
        });

        bookingDetails.replaceChildren(card);

    } catch (error) {
        bookingDetails.textContent = error.message;
    }
});


loadLocations();