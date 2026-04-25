-- Editor-service baseline schema.
-- Includes document aggregates plus platform-resource catalog/outbox tables.

CREATE TABLE IF NOT EXISTS documents (
	document_id CHAR(36) NOT NULL,
	created_at DATETIME(6) NOT NULL,
	updated_at DATETIME(6) NOT NULL,
	version INT NOT NULL,
	created_by VARCHAR(64) NULL,
	deleted_at DATETIME(6) NULL,
	modified_by VARCHAR(64) NULL,
	cover_json LONGTEXT NULL,
	icon_json LONGTEXT NULL,
	sort_key VARCHAR(255) NOT NULL,
	title VARCHAR(255) NOT NULL,
	visibility ENUM('PRIVATE', 'PUBLIC') NOT NULL,
	parent_id CHAR(36) NULL,
	PRIMARY KEY (document_id),
	KEY fk_documents_parent (parent_id),
	CONSTRAINT fk_documents_parent
		FOREIGN KEY (parent_id) REFERENCES documents (document_id)
		ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS blocks (
	block_id CHAR(36) NOT NULL,
	created_at DATETIME(6) NOT NULL,
	updated_at DATETIME(6) NOT NULL,
	version INT NOT NULL,
	created_by VARCHAR(64) NULL,
	deleted_at DATETIME(6) NULL,
	modified_by VARCHAR(64) NULL,
	content_json LONGTEXT NOT NULL,
	sort_key VARCHAR(24) NOT NULL,
	type ENUM('TEXT') NOT NULL,
	document_id CHAR(36) NOT NULL,
	parent_id CHAR(36) NULL,
	PRIMARY KEY (block_id),
	KEY fk_blocks_document (document_id),
	KEY fk_blocks_parent (parent_id),
	CONSTRAINT fk_blocks_document
		FOREIGN KEY (document_id) REFERENCES documents (document_id)
		ON DELETE CASCADE,
	CONSTRAINT fk_blocks_parent
		FOREIGN KEY (parent_id) REFERENCES blocks (block_id)
		ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS document_resources (
	document_resource_id CHAR(36) NOT NULL,
	created_at DATETIME(6) NOT NULL,
	updated_at DATETIME(6) NOT NULL,
	version INT NOT NULL,
	created_by VARCHAR(64) NULL,
	deleted_at DATETIME(6) NULL,
	modified_by VARCHAR(64) NULL,
	block_id CHAR(36) NULL,
	document_id CHAR(36) NOT NULL,
	document_version BIGINT NULL,
	last_error VARCHAR(2048) NULL,
	owner_user_id VARCHAR(64) NOT NULL,
	purge_at DATETIME(6) NULL,
	repaired_at DATETIME(6) NULL,
	resource_id VARCHAR(128) NOT NULL,
	resource_kind VARCHAR(64) NOT NULL,
	sort_order INT NULL,
	status ENUM('ACTIVE', 'BROKEN', 'PENDING_PURGE', 'PURGED', 'TRASHED') NOT NULL,
	usage_type ENUM('BLOCK_ATTACHMENT', 'DOCUMENT_SNAPSHOT') NOT NULL,
	PRIMARY KEY (document_resource_id)
);

CREATE TABLE IF NOT EXISTS platform_resource_catalog (
	id VARCHAR(128) NOT NULL,
	owner_type VARCHAR(128) NOT NULL,
	owner_id VARCHAR(256) NOT NULL,
	kind VARCHAR(128) NOT NULL,
	storage_file_id VARCHAR(512) NOT NULL,
	original_name VARCHAR(1024) NULL,
	content_type VARCHAR(255) NULL,
	size_bytes BIGINT NOT NULL,
	attributes LONGTEXT NULL,
	status VARCHAR(32) NOT NULL,
	created_at TIMESTAMP NOT NULL,
	deleted_at TIMESTAMP NULL,
	PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS platform_resource_outbox (
	id VARCHAR(128) NOT NULL,
	operation VARCHAR(64) NOT NULL,
	resource_id VARCHAR(128) NOT NULL,
	payload LONGTEXT NOT NULL,
	status VARCHAR(32) NOT NULL,
	attempts INT NOT NULL,
	last_error VARCHAR(2048) NULL,
	created_at TIMESTAMP NOT NULL,
	updated_at TIMESTAMP NOT NULL,
	PRIMARY KEY (id)
);
