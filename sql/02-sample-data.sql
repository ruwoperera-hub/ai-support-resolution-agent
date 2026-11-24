insert into customers (email, name, tier) values
 ('anna@example.com','Anna Perera','standard'),
 ('ravi@example.com','Ravi Silva','vip'),
 ('arutha@example.com','Arutha Perera','standard'),
 ('dinesh.j@example.com','Dinesh Jayawardena','vip')
on conflict (email) do nothing;

insert into orders (id, customer_id, status, total, tracking_number, placed_at, delivered_at)
select v.id, c.id, v.status, v.total, v.tracking, now() - v.age, v.delivered
from (values
 ('ORD-1001','anna@example.com','shipped',49.99,'LK123456789', interval '3 days', null::timestamptz),
 ('ORD-1002','ravi@example.com','processing',120.00,null, interval '1 day', null),
 ('ORD-1003','arutha@example.com','shipped',35.50,'LK555000111', interval '4 days', null),
 ('ORD-1004','anna@example.com','delivered',89.00,'LK222333444', interval '9 days', now() - interval '5 days'),
 ('ORD-1005','ravi@example.com','delivered',250.00,'LK777888999', interval '12 days', now() - interval '8 days'),
 ('ORD-1006','arutha@example.com','refunded',60.00,null, interval '20 days', null),
 ('ORD-1007','dinesh.j@example.com','processing',75.00,null, interval '2 days', null),
 ('ORD-1008','dinesh.j@example.com','delivered',150.00,'LK101010101', interval '7 days', now() - interval '3 days'),
 ('ORD-1009','dinesh.j@example.com','delivered',99.90,'LK202020202', interval '10 days', now() - interval '6 days'),
 ('ORD-1010','anna@example.com','processing',20.00,null, interval '1 day', null)
) as v(id, email, status, total, tracking, age, delivered)
join customers c on c.email = v.email
on conflict (id) do nothing;

-- Sample knowledge base (embeddings are filled by the KB Ingestion workflow)
insert into kb_chunks (document, content) values
('Refund Policy', 'Customers can request a refund within 30 days of delivery. The item must be unused and in its original packaging. Refunds are returned to the original payment method within 5 to 7 business days after we receive the item. Refunds above $100 need manager approval.'),
('Shipping Times', 'Standard shipping takes 3 to 7 business days within Sri Lanka and 7 to 14 business days internationally. Express shipping takes 1 to 3 business days. Orders are processed within 24 hours on business days.'),
('Order Tracking', 'Once an order ships, a tracking number is added to the order. Customers can track it on the courier website. If an order has not moved for 5 days, contact support so we can open a courier investigation.'),
('Order Cancellation', 'Orders can be cancelled free of charge while the status is processing. Once an order has shipped, it cannot be cancelled, but the customer can refuse delivery or return it after receiving it.'),
('Damaged or Wrong Items', 'If an item arrives damaged or incorrect, customers should send a photo within 7 days of delivery. We will send a replacement or give a full refund, including shipping costs, at no extra charge.'),
('Account and Password', 'To reset a password, use the Forgot Password link on the login page. A reset email arrives within 5 minutes. Check the spam folder. For security, support agents can never ask for or see a customer password.'),
('Billing and Payments', 'We accept major credit cards and bank transfers. A duplicate charge is usually a temporary payment authorization that disappears within 3 to 5 business days. If it remains after that, contact support with the order number.'),
('Warranty', 'Electronic products include a 12-month warranty against manufacturing defects. The warranty does not cover physical damage, water damage or misuse. Customers need their order number to make a warranty claim.');
