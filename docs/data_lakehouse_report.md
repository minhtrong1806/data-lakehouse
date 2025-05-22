# Báo Cáo Tổng Quan Về Dự Án Data Lakehouse

## Giới Thiệu
Dự án Data Lakehouse này được thiết kế để xây dựng một hệ thống quản lý dữ liệu hiện đại, kết hợp các tính năng của Data Lake và Data Warehouse. Hệ thống này sử dụng các công nghệ như Dagster, DBT, Spark-Iceberg, và Trino để xử lý, biến đổi và phân tích dữ liệu chuỗi cung ứng (supply chain).

## Kiến Trúc Tổng Quan
Hệ thống Data Lakehouse được tổ chức thành nhiều thành phần chính:
- **Dagster**: Dùng để điều phối các pipeline dữ liệu, bao gồm việc chạy các mô hình DBT và xử lý PySpark.
- **DBT (Data Build Tool)**: Quản lý quá trình biến đổi dữ liệu qua các tầng Bronze, Silver và Gold.
- **Spark-Iceberg**: Hỗ trợ xử lý dữ liệu lớn và lưu trữ dữ liệu dạng bảng với định dạng Iceberg.
- **Trino**: Công cụ truy vấn phân tán để truy cập và phân tích dữ liệu từ nhiều nguồn.
- **MinIO**: Lưu trữ đối tượng (object storage) cho dữ liệu thô và dữ liệu đã xử lý.
- **PostgreSQL**: Cơ sở dữ liệu quan hệ để lưu trữ dữ liệu nguồn.
- **Metabase**: Công cụ trực quan hóa dữ liệu để tạo báo cáo và dashboard.

![Kiến Trúc Data Lakehouse](../docs/data_lakehouse_architecture.png)

## Pipeline Dữ Liệu
Dữ liệu trong hệ thống được xử lý qua ba tầng chính: Bronze, Silver và Gold, với các pipeline được định nghĩa trong Dagster.

### 1. Pipeline Biến Đổi Dữ Liệu (DBT Transformation Pipeline)
Pipeline này chạy các mô hình DBT theo thứ tự:
- **Bronze**: Thu thập và chuẩn hóa dữ liệu thô từ các nguồn như bảng `orders`, `products`, `customers`, v.v.
- **Silver**: Làm sạch và làm giàu dữ liệu, ví dụ tính toán lợi nhuận cho mỗi đơn hàng.
- **Gold**: Tổng hợp dữ liệu thành các bảng sự kiện (fact) và bảng chiều (dimension) để phục vụ phân tích, như bảng `fact_sales`.

### 2. Pipeline Dữ Liệu Streaming Clickstream (DBT Clickstream Pipeline)
Pipeline này tập trung vào xử lý dữ liệu streaming clickstream:
- **Bronze**: Dữ liệu clickstream được đọc từ Kafka topic `clickstream` bằng Spark, sau đó được xử lý để phân tích URL (bao gồm các thông tin như department, category, product, và hành động thêm vào giỏ hàng) và xác định quốc gia từ địa chỉ IP. Dữ liệu sau đó được ghi vào bảng Iceberg `lakehouse.bronze.raw_clickstream`.
- **Silver**: Xử lý dữ liệu clickstream thô từ tầng Bronze thành định dạng có cấu trúc.
- **Gold**: Tổng hợp dữ liệu clickstream thành bảng sự kiện `fact_clickstream`.

![Pipeline Dữ Liệu](../docs/pipelines.png)

### 3. Pipeline Phân Khúc Khách Hàng (Customer Segmentation Pipeline)
Pipeline này sử dụng PySpark để thực hiện phân khúc khách hàng dựa trên các chỉ số RFM (Recency, Frequency, Monetary):
- Đọc dữ liệu từ các bảng `fact_sales` và `dim_customer` ở tầng Gold.
- Tính toán các chỉ số RFM và áp dụng kỹ thuật feature engineering.
- Dự đoán phân khúc khách hàng sử dụng mô hình KMeans đã được huấn luyện.
- Lưu kết quả vào bảng `customer_rfm_segments` với cơ chế SCD Type 2 để theo dõi lịch sử thay đổi.

## Các Thành Phần Dữ Liệu Chính
- **Dữ Liệu Chuỗi Cung Ứng (Supply Chain Data)**: Bao gồm thông tin về đơn hàng, sản phẩm, khách hàng, cửa hàng, và vận chuyển.
- **Dữ Liệu Clickstream**: Dữ liệu streaming về hành vi người dùng trên nền tảng trực tuyến.
- **Dữ Liệu Phân Khúc Khách Hàng**: Kết quả phân tích RFM để phân loại khách hàng theo các phân khúc khác nhau.

![Schema Chuỗi Cung Ứng](../docs/supply_chain_schema.png)

## Các Notebook Phân Tích
Dự án bao gồm các notebook Jupyter để thực hiện phân tích dữ liệu:
- **CustomerSegmentation.ipynb**: Phân tích và phân khúc khách hàng dựa trên dữ liệu bán hàng.
- **streaming_logs.ipynb**: Xử lý và phân tích dữ liệu streaming logs.
- **test.ipynb**: Notebook thử nghiệm cho các mục đích khác.

## Kết Luận
Dự án Data Lakehouse này cung cấp một nền tảng mạnh mẽ để quản lý, xử lý và phân tích dữ liệu chuỗi cung ứng và dữ liệu streaming. Với kiến trúc phân tầng và các pipeline tự động hóa, hệ thống đảm bảo dữ liệu được biến đổi từ dạng thô sang dạng sẵn sàng cho phân tích kinh doanh, đồng thời hỗ trợ các kỹ thuật học máy như phân khúc khách hàng.

Nếu có bất kỳ câu hỏi hoặc yêu cầu bổ sung thông tin, vui lòng liên hệ nhóm phát triển dự án.