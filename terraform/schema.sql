
CREATE TABLE IF NOT EXISTS buses (
    bus_id INT AUTO_INCREMENT PRIMARY KEY,
    bus_name VARCHAR(100) NOT NULL,
    bus_type VARCHAR(50),
    registration_number VARCHAR(30) UNIQUE,
    total_seats INT NOT NULL
);

CREATE TABLE IF NOT EXISTS trips (
    trip_id INT AUTO_INCREMENT PRIMARY KEY,
    bus_id INT NOT NULL,
    source VARCHAR(100) NOT NULL,
    destination VARCHAR(100) NOT NULL,
    departure_time DATETIME NOT NULL,
    arrival_time DATETIME NOT NULL,
    fare DECIMAL(10,2) NOT NULL,
    available_seats INT NOT NULL,
    FOREIGN KEY (bus_id) REFERENCES buses(bus_id),
    INDEX idx_trip_search (source, destination, departure_time)
);

CREATE TABLE IF NOT EXISTS passengers (
    passenger_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    age INT NOT NULL,
    gender VARCHAR(20),
    phone VARCHAR(15) NOT NULL,
    email VARCHAR(150)
);

CREATE TABLE IF NOT EXISTS bookings (
    booking_id INT AUTO_INCREMENT PRIMARY KEY,
    booking_reference VARCHAR(40) UNIQUE NOT NULL,
    passenger_id INT NOT NULL,
    trip_id INT NOT NULL,
    seats_booked INT NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    booking_status ENUM('CONFIRMED','CANCELLED') DEFAULT 'CONFIRMED',
    booked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (passenger_id) REFERENCES passengers(passenger_id),
    FOREIGN KEY (trip_id) REFERENCES trips(trip_id)
);

-- Insert buses only if they do not already exist.
INSERT IGNORE INTO buses
(bus_name, bus_type, registration_number, total_seats)
VALUES
('GoBus Hyderabad Express','AC Sleeper','AP01AB1001',40),
('GoBus Hyderabad Night','AC Seater','AP01AB1002',40),
('GoBus Hyderabad Superfast','Non AC Sleeper','AP01AB1003',40),
('GoBus Vizag Express','AC Sleeper','AP31CD2001',40),
('GoBus Vizag Coastal','AC Seater','AP31CD2002',40),
('GoBus Vizag Superfast','Non AC Sleeper','AP31CD2003',40),
('GoBus Vizianagaram Express','AC Sleeper','AP35EF3001',40),
('GoBus Vizianagaram Coastal','AC Seater','AP35EF3002',40),
('GoBus Vizianagaram Night','Non AC Sleeper','AP35EF3003',40);

-- Generate trips for the next 30 days.
-- Existing trips are skipped, so running this repeatedly is safe.
INSERT INTO trips
(bus_id, source, destination, departure_time, arrival_time, fare, available_seats)
SELECT
    b.bus_id,
    x.source,
    x.destination,
    TIMESTAMP(d.travel_day, '18:00:00'),
    TIMESTAMP(d.travel_day + INTERVAL 1 DAY, '06:00:00'),
    x.fare,
    b.total_seats
FROM buses b
JOIN (
    SELECT 'AP01AB1001' reg, 'Hyderabad' source, 'Chennai' destination, 1200.00 fare
    UNION ALL SELECT 'AP01AB1002','Hyderabad','Palasa',1000.00
    UNION ALL SELECT 'AP01AB1003','Hyderabad','Sompeta',1100.00
    UNION ALL SELECT 'AP31CD2001','Vizag','Chennai',950.00
    UNION ALL SELECT 'AP31CD2002','Vizag','Palasa',500.00
    UNION ALL SELECT 'AP31CD2003','Vizag','Sompeta',600.00
    UNION ALL SELECT 'AP35EF3001','Vizianagaram','Chennai',1050.00
    UNION ALL SELECT 'AP35EF3002','Vizianagaram','Palasa',400.00
    UNION ALL SELECT 'AP35EF3003','Vizianagaram','Sompeta',550.00
) x ON x.reg = b.registration_number
CROSS JOIN (
    SELECT CURDATE() + INTERVAL 1 DAY AS travel_day
    UNION ALL SELECT CURDATE() + INTERVAL 2 DAY
    UNION ALL SELECT CURDATE() + INTERVAL 3 DAY
    UNION ALL SELECT CURDATE() + INTERVAL 4 DAY
    UNION ALL SELECT CURDATE() + INTERVAL 5 DAY
    UNION ALL SELECT CURDATE() + INTERVAL 6 DAY
    UNION ALL SELECT CURDATE() + INTERVAL 7 DAY
    UNION ALL SELECT CURDATE() + INTERVAL 8 DAY
    UNION ALL SELECT CURDATE() + INTERVAL 9 DAY
    UNION ALL SELECT CURDATE() + INTERVAL 10 DAY
    UNION ALL SELECT CURDATE() + INTERVAL 11 DAY
    UNION ALL SELECT CURDATE() + INTERVAL 12 DAY
    UNION ALL SELECT CURDATE() + INTERVAL 13 DAY
    UNION ALL SELECT CURDATE() + INTERVAL 14 DAY
    UNION ALL SELECT CURDATE() + INTERVAL 15 DAY
    UNION ALL SELECT CURDATE() + INTERVAL 16 DAY
    UNION ALL SELECT CURDATE() + INTERVAL 17 DAY
    UNION ALL SELECT CURDATE() + INTERVAL 18 DAY
    UNION ALL SELECT CURDATE() + INTERVAL 19 DAY
    UNION ALL SELECT CURDATE() + INTERVAL 20 DAY
    UNION ALL SELECT CURDATE() + INTERVAL 21 DAY
    UNION ALL SELECT CURDATE() + INTERVAL 22 DAY
    UNION ALL SELECT CURDATE() + INTERVAL 23 DAY
    UNION ALL SELECT CURDATE() + INTERVAL 24 DAY
    UNION ALL SELECT CURDATE() + INTERVAL 25 DAY
    UNION ALL SELECT CURDATE() + INTERVAL 26 DAY
    UNION ALL SELECT CURDATE() + INTERVAL 27 DAY
    UNION ALL SELECT CURDATE() + INTERVAL 28 DAY
    UNION ALL SELECT CURDATE() + INTERVAL 29 DAY
    UNION ALL SELECT CURDATE() + INTERVAL 30 DAY
) d
WHERE NOT EXISTS (
    SELECT 1
    FROM trips t
    WHERE t.bus_id = b.bus_id
      AND t.source = x.source
      AND t.destination = x.destination
      AND DATE(t.departure_time) = d.travel_day
);
