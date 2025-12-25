# IoT Device Heartbeat Monitoring and Email Alerting System

## 1. Project Overview and Idea

In modern IoT (Internet of Things) deployments, devices are often distributed across multiple locations and are expected to operate continuously with minimal human intervention. Ensuring the health and availability of these devices is critical, especially in environments such as manufacturing, smart infrastructure, logistics, and monitoring systems. One of the most common indicators of device health is the periodic *heartbeat* or *hello* message sent by the device to a backend system.

The core idea of this project is to design and implement a **scalable, fault-tolerant alerting application** that automatically notifies concerned teams via email when an IoT device stops sending its heartbeat message for a defined period of time. Instead of relying on manual checks or tightly coupled systems, the solution leverages **event-driven architecture**, **Apache Kafka**, and **AWS-managed infrastructure** to ensure reliability, scalability, and observability.

The system continuously ingests heartbeat messages, tracks device activity, detects anomalies based on configurable time thresholds, and triggers alerts through an asynchronous messaging pipeline. The entire solution is deployed on AWS using containerized services running on Amazon ECS, with Kafka hosted on EC2 for fine-grained control.

---

## 2. Objectives of the Project

The main objectives of the project are:

* To reliably ingest heartbeat messages from IoT devices.
* To decouple data ingestion, processing, and alerting using an event-driven architecture.
* To detect device inactivity based on a configurable timeout window.
* To generate and send alert emails automatically when a device becomes unresponsive.
* To ensure scalability and resilience using AWS cloud services.
* To provide a modular architecture that can be extended to support additional alerting mechanisms in the future (e.g., SMS, Slack, PagerDuty).

---

## 3. High-Level Architecture

The solution follows a **producer–consumer model** with Kafka as the messaging backbone. The major components are:

1. **IoT Device / Client** – Sends periodic heartbeat (hello) messages.
2. **Route 53** – Provides DNS-based routing to the ingestion service.
3. **Data Ingestion Service** – Receives incoming requests and publishes messages to Kafka.
4. **Kafka Broker (EC2)** – Acts as the central event streaming platform.
5. **Consumer Service** – Consumes heartbeat messages and tracks device activity.
6. **Alert Topic** – Kafka topic dedicated to alert events.
7. **Alert Service** – Consumes alert messages and sends email notifications.
8. **Amazon ECS** – Hosts all microservices in containers.

All services are loosely coupled, enabling independent scaling, deployment, and fault isolation.

---

## 4. Detailed System Flow

The system follows a fully event-driven, producer–consumer workflow implemented using Apache Kafka. The following subsections describe the **actual verified application behavior** based on the implemented services.

### 4.1 Heartbeat Message Ingestion

IoT devices (or simulated clients using `curl`) send periodic heartbeat (hello) messages containing at least a `device_id` and timestamp. These HTTP requests are routed via **Amazon Route 53** to the **Data Ingestion Service** running on Amazon ECS.

Internally, the ingestion layer uses Kafka producer logic (as implemented in `kafka_producer.py`) to serialize the heartbeat payload as JSON and publish it to the Kafka topic **`iot-data`**. Connection retries and acknowledgment settings (`acks=all`) ensure reliable delivery even during broker startup delays.

---

### 4.2 Kafka Broker (EC2)

Apache Kafka is deployed on Amazon EC2 and serves as the central messaging backbone. It decouples producers from consumers and provides durability, ordering, and replayability. Topics are logically separated as:

* `iot-data` – device heartbeat events
* `device-alerts` – alert and recovery events

Kafka retry logic in all services ensures resilience against temporary broker unavailability.

---

### 4.3 Consumer Service – Device Monitoring

The **Consumer Service** (implemented in `consumer.py`) subscribes to the `iot-data` topic and performs continuous device health monitoring.

Key behaviors:

* Maintains an **in-memory, thread-safe map** of `device_id → last_seen_timestamp`
* Periodically checks device activity using a background monitoring thread
* Triggers a **DEVICE_DOWN** alert if no heartbeat is received within a configurable timeout (`DEVICE_TIMEOUT`)
* Triggers a **DEVICE_RECOVERED** alert when a previously down device resumes communication

To prevent duplicate alerts, the service tracks device state transitions (UP → DOWN → UP). All alert events are published to the Kafka topic **`device-alerts`**.

The service also exposes **Prometheus metrics** (e.g., number of IoT messages consumed), enabling observability and monitoring.

---

### 4.4 Alert Topic and Alert Service

Alert events published to `device-alerts` are consumed by the **Alert Service** (`email_client.py`). This service:

* Subscribes to the alert topic using a dedicated consumer group
* Formats alert details into a human-readable email
* Sends notifications via SMTP (Gmail) to the configured recipient group

Each alert email contains device ID, severity, timestamp, and a descriptive message, ensuring operational teams can take timely action.

---

### 4.2 Data Ingestion Service

The **Data Ingestion Service** is a containerized application running on Amazon ECS. Its responsibilities include:

* Validating incoming requests
* Parsing device heartbeat data
* Publishing the message to a Kafka topic (e.g., `device-heartbeat`)

By immediately placing incoming data onto Kafka, the service remains lightweight and stateless, allowing it to handle large volumes of concurrent requests efficiently.

---

### 4.3 Kafka Broker on EC2

Apache Kafka serves as the central message broker for the system. In this project:

* Kafka is deployed on Amazon EC2 for greater control over configuration and networking.
* Topics are partitioned to support scalability and parallel processing.
* Kafka ensures durability and fault tolerance through replication.

Kafka decouples producers (ingestion service) from consumers (monitoring and alert services), ensuring that temporary service failures do not result in data loss.

---

### 4.4 Consumer Service (Device Monitoring)

The **Consumer Service**, running on ECS, subscribes to the heartbeat topic. Its main responsibilities are:

* Consuming heartbeat messages from Kafka
* Maintaining a record of the last-seen timestamp for each device
* Periodically evaluating device activity

The service uses an internal scheduler or background task to compare the current time with the last heartbeat received for each device. If the difference exceeds a predefined threshold (for example, 5 or 10 minutes), the device is considered *inactive*.

---

### 4.5 Alert Generation and Alert Topic

When a device is detected as inactive:

* The Consumer Service generates an alert event
* The alert message includes device ID, last-seen time, and alert severity
* The message is published to a dedicated Kafka topic (e.g., `device-alerts`)

Using a separate alert topic ensures a clean separation between normal telemetry data and critical alerting events.

---

### 4.6 Alert Service and Email Notification

The **Alert Service** subscribes to the alert topic and is responsible for:

* Consuming alert messages
* Formatting email notifications
* Sending emails to the concerned department using SMTP or an email service

The email typically contains:

* Device identifier
* Timestamp of last heartbeat
* Alert description
* Suggested action

This service is also containerized and deployed on ECS, allowing it to scale independently based on alert volume.

---

## 5. Deployment on AWS

### 5.1 Amazon ECS

All microservices (ingestion, consumer, and alert services) run on **Amazon ECS**. ECS provides:

* Container orchestration
* Health checks and service restarts
* Easy scaling and deployment

The services are defined using task definitions, and environment variables are used for configuration such as Kafka brokers, topic names, and timeout values.

---

### 5.2 Networking and Security

* Services run within a VPC for isolation.
* Security groups restrict access between ECS services and the Kafka EC2 instance.
* Only required ports (e.g., Kafka broker port, application ports) are exposed.

Secrets such as email credentials are managed using AWS Secrets Manager or environment variables.

---

## 6. Configuration and Time Thresholds

A key feature of the system is the **configurable inactivity threshold**. This value determines how long a device can remain silent before triggering an alert. The threshold can be:

* Configured per service using environment variables
* Adjusted without changing application code

This flexibility allows the system to support different device types with varying heartbeat frequencies.

---

## 7. Scalability and Fault Tolerance

The architecture is designed with scalability and resilience in mind:

* Kafka handles high-throughput message ingestion.
* ECS enables horizontal scaling of services.
* Stateless services reduce recovery time after failures.
* Message replay from Kafka allows reprocessing in case of downstream failures.

---

## 8. Challenges Faced

### 8.1 Kafka Management on EC2

Operating Kafka on EC2 required careful configuration of broker settings, disk space, and network security. While this approach provides flexibility and control, it also introduces operational overhead compared to managed services.

---

### 8.2 Time-Based Alert Detection

Implementing accurate inactivity detection involved handling:

* Time synchronization between services
* Delayed or bursty heartbeat messages
* Avoiding duplicate alerts for the same outage

This was mitigated using stateful device tracking and explicit UP/DOWN state transitions in the consumer service.

---

### 8.3 In-Memory State Management

The consumer service maintains device state in memory for performance and simplicity. While effective for this project, this design means:

* Device state is lost if the container restarts
* Alerts may be re-triggered after restarts

This limitation is acceptable for a prototype but should be addressed with persistent storage in production systems.

---

### 8.4 Email Reliability and Alert Storms

Using SMTP-based email alerting introduces challenges such as transient failures and the risk of alert storms during large outages. Retry handling is partially addressed in the application, but production systems should include throttling, aggregation, or alternative alert channels.

---

### 8.2 Time-Based Alert Logic

Accurately detecting inactivity required careful handling of:

* Clock synchronization
* Delayed or out-of-order messages
* Avoiding duplicate alerts for the same device

This was addressed by maintaining consistent timestamps and alert suppression logic.

---

### 8.3 Email Reliability

Ensuring reliable email delivery involved:

* Handling SMTP failures
* Retrying failed email sends
* Preventing alert storms during large outages

---

## 9. Future Enhancements

Potential future improvements include:

* Migrating Kafka to a managed service
* Adding a dashboard for device health visualization
* Supporting multiple alert channels (SMS, Slack)
* Persisting device state in a database for long-term analytics

---

## 10. Conclusion

This project demonstrates a robust, cloud-native approach to monitoring IoT device health using AWS, Kafka, and containerized microservices. By leveraging an event-driven architecture, the system achieves scalability, resilience, and flexibility while providing timely alerts to operational teams. The solution can be easily extended and adapted to support larger deployments and additional monitoring requirements, making it suitable for real-world enterprise IoT environments.
