-- 1. Tạo bảng với CHECK ngay từ đầu
CREATE TABLE customers (
    customer_id INTEGER PRIMARY KEY,
    customer_fname VARCHAR(100),
    customer_lname VARCHAR(100),
    customer_email VARCHAR(255) UNIQUE,
    customer_password TEXT,
    customer_segment VARCHAR(20) CHECK (customer_segment IN ('Consumer', 'Corporate', 'Home Office')),
    customer_street TEXT,
    customer_city VARCHAR(100),
    customer_state VARCHAR(100),
    customer_zipcode VARCHAR(20),
    customer_country VARCHAR(100)
);

CREATE TABLE categories (
    category_id INTEGER PRIMARY KEY,
    category_name VARCHAR(100)
);

CREATE TABLE products (
    product_id INTEGER PRIMARY KEY,
    product_name VARCHAR(100),
    product_description TEXT,
    product_price DECIMAL(10, 2),
    product_status BOOLEAN,
    category_id INTEGER,
    product_image TEXT,
    CONSTRAINT fk_category FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE CASCADE
);

CREATE TABLE departments (
    department_id INTEGER PRIMARY KEY,
    department_name VARCHAR(100)
);

CREATE TABLE stores (
    store_id SERIAL PRIMARY KEY,
    store_name VARCHAR(100),
    store_latitude DECIMAL(9, 6),
    store_longitude DECIMAL(9, 6)
);

CREATE TABLE store_departments (
    store_id INTEGER,
    department_id INTEGER,
    PRIMARY KEY (store_id, department_id),
    FOREIGN KEY (store_id) REFERENCES stores(store_id) ON DELETE CASCADE,
    FOREIGN KEY (department_id) REFERENCES departments(department_id) ON DELETE CASCADE
);


CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY,
    order_date DATE,
    order_customer_id INTEGER,
    store_id INTEGER,
    order_status VARCHAR(20) CHECK (order_status IN ('COMPLETE', 'PENDING', 'CLOSED', 'PENDING_PAYMENT', 'CANCELED', 'PROCESSING', 'SUSPECTED_FRAUD', 'ON_HOLD', 'PAYMENT_REVIEW')),
    order_city VARCHAR(100),
    order_state VARCHAR(100),
    order_country VARCHAR(100),
    order_region VARCHAR(100),
    order_market VARCHAR(100) CHECK (order_market IN ('Africa', 'Europe', 'LATAM', 'Pacific Asia', 'USCA')),
    sales DECIMAL(10, 2),
    payment_type VARCHAR(100),
    store_latitude DECIMAL(9, 6),
    store_longitude DECIMAL(9, 6),
    order_profit_per_order DECIMAL(10, 2),
    CONSTRAINT fk_customer FOREIGN KEY (order_customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE,
    CONSTRAINT fk_store FOREIGN KEY (store_id) REFERENCES stores(store_id) ON DELETE SET NULL
);

CREATE TABLE order_items (
    order_item_id INTEGER PRIMARY KEY,
    order_id INTEGER,
    product_id INTEGER,
    quantity INTEGER,
    unit_price DECIMAL(10, 2),
    discount DECIMAL(10, 2),
    discount_rate DECIMAL(5, 2) CHECK (discount_rate BETWEEN 0 AND 1),
    total_price DECIMAL(10, 2),
    profit_ratio DECIMAL(5, 2),
    CONSTRAINT fk_order FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    CONSTRAINT fk_product FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE
);

CREATE TABLE shipping (
    shipping_id SERIAL PRIMARY KEY,
    order_id INTEGER,
    shipping_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    shipping_mode VARCHAR(20) CHECK (shipping_mode IN ('Standard Class', 'First Class', 'Second Class', 'Same Day')),
    days_for_shipping_real INTEGER,
    days_for_shipment_scheduled INTEGER,
    delivery_status VARCHAR(20) CHECK (delivery_status IN ('Advance shipping', 'Late delivery', 'Shipping canceled', 'Shipping on time')),
    late_delivery_risk BOOLEAN,
    CONSTRAINT fk_shipping_order FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE
);

-- 2. Thêm INDEX để tối ưu truy vấn
CREATE INDEX idx_orders_customer ON orders(order_customer_id);
CREATE INDEX idx_orders_store ON orders(store_id);
CREATE INDEX idx_orders_date ON orders(order_date);