# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_03_16_083920) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "attendances", force: :cascade do |t|
    t.date "attendance_date", null: false
    t.integer "classroom_id", null: false
    t.datetime "created_at", null: false
    t.datetime "marked_at"
    t.integer "marked_by_id"
    t.text "remarks"
    t.integer "status", default: 0, null: false
    t.integer "student_id", null: false
    t.datetime "updated_at", null: false
    t.index ["attendance_date"], name: "index_attendances_on_attendance_date"
    t.index ["classroom_id", "attendance_date"], name: "index_attendances_on_classroom_id_and_attendance_date"
    t.index ["classroom_id"], name: "index_attendances_on_classroom_id"
    t.index ["marked_by_id"], name: "index_attendances_on_marked_by_id"
    t.index ["student_id", "attendance_date"], name: "index_attendances_on_student_id_and_attendance_date", unique: true
    t.index ["student_id"], name: "index_attendances_on_student_id"
  end

  create_table "audit_logs", force: :cascade do |t|
    t.string "action", null: false
    t.integer "auditable_id", null: false
    t.string "auditable_type", null: false
    t.datetime "created_at", null: false
    t.text "metadata"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["auditable_type", "auditable_id"], name: "index_audit_logs_on_auditable_type_and_auditable_id"
    t.index ["created_at"], name: "index_audit_logs_on_created_at"
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "classrooms", force: :cascade do |t|
    t.integer "academic_year"
    t.integer "capacity"
    t.integer "class_teacher_id"
    t.datetime "created_at", null: false
    t.integer "grade_level"
    t.string "name"
    t.string "room_number"
    t.string "section"
    t.datetime "updated_at", null: false
    t.index ["class_teacher_id"], name: "index_classrooms_on_class_teacher_id"
    t.index ["grade_level"], name: "index_classrooms_on_grade_level"
    t.index ["name", "academic_year"], name: "index_classrooms_on_name_and_academic_year", unique: true
  end

  create_table "events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "end_datetime"
    t.integer "event_type"
    t.string "location"
    t.boolean "registration_required"
    t.datetime "start_datetime"
    t.integer "target_audience"
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "fee_assignments", force: :cascade do |t|
    t.decimal "amount_override", precision: 12, scale: 2
    t.datetime "created_at", null: false
    t.decimal "discount_amount", precision: 12, scale: 2, default: "0.0"
    t.decimal "discount_percent", precision: 5, scale: 2, default: "0.0"
    t.boolean "exempt", default: false, null: false
    t.integer "fee_id", null: false
    t.integer "installment_count", default: 1
    t.integer "status", default: 0, null: false
    t.integer "student_id", null: false
    t.datetime "updated_at", null: false
    t.index ["fee_id", "student_id"], name: "index_fee_assignments_on_fee_id_and_student_id", unique: true
    t.index ["fee_id"], name: "index_fee_assignments_on_fee_id"
    t.index ["student_id"], name: "index_fee_assignments_on_student_id"
  end

  create_table "fees", force: :cascade do |t|
    t.integer "academic_year", null: false
    t.decimal "amount", precision: 12, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.date "due_date"
    t.integer "fee_type", default: 0, null: false
    t.string "name", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["academic_year", "fee_type"], name: "index_fees_on_academic_year_and_fee_type"
  end

  create_table "invoice_line_items", force: :cascade do |t|
    t.decimal "amount", precision: 12, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.string "description", default: "", null: false
    t.integer "fee_assignment_id"
    t.integer "invoice_id", null: false
    t.integer "quantity", default: 1, null: false
    t.decimal "unit_amount", precision: 12, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.index ["fee_assignment_id"], name: "index_invoice_line_items_on_fee_assignment_id"
    t.index ["invoice_id"], name: "index_invoice_line_items_on_invoice_id"
  end

  create_table "invoices", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "due_date", null: false
    t.date "issue_date", null: false
    t.text "notes"
    t.integer "status", default: 0, null: false
    t.integer "student_id", null: false
    t.decimal "total_amount", precision: 12, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_invoices_on_status"
    t.index ["student_id", "issue_date"], name: "index_invoices_on_student_id_and_issue_date"
    t.index ["student_id"], name: "index_invoices_on_student_id"
  end

  create_table "notices", force: :cascade do |t|
    t.boolean "active", default: true
    t.integer "author_id"
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.string "grade_levels", default: ""
    t.integer "notice_type"
    t.integer "priority"
    t.datetime "published_at"
    t.integer "target_audience"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_notices_on_active"
    t.index ["author_id"], name: "index_notices_on_author_id"
    t.index ["expires_at"], name: "index_notices_on_expires_at"
    t.index ["priority"], name: "index_notices_on_priority"
    t.index ["published_at"], name: "index_notices_on_published_at"
    t.index ["target_audience"], name: "index_notices_on_target_audience"
  end

  create_table "parent_profiles", force: :cascade do |t|
    t.text "address"
    t.datetime "created_at", null: false
    t.string "employer"
    t.string "occupation"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_parent_profiles_on_user_id", unique: true
  end

  create_table "parent_student_relationships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "parent_id", null: false
    t.string "relationship_type", default: "parent"
    t.integer "student_id", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_id", "student_id"], name: "index_parent_student_relationships_on_parent_and_student", unique: true
    t.index ["parent_id"], name: "index_parent_student_relationships_on_parent_id"
    t.index ["student_id"], name: "index_parent_student_relationships_on_student_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.integer "byte_size", limit: 4, null: false
    t.datetime "created_at", null: false
    t.binary "key", limit: 1024, null: false
    t.integer "key_hash", limit: 8, null: false
    t.binary "value", limit: 536870912, null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "students", force: :cascade do |t|
    t.date "admission_date"
    t.string "admission_number"
    t.text "allergies"
    t.string "blood_group"
    t.integer "classroom_id"
    t.datetime "created_at", null: false
    t.date "date_of_birth"
    t.string "emergency_contact_name"
    t.string "emergency_contact_phone"
    t.text "medical_conditions"
    t.text "special_needs"
    t.integer "status", default: 0
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["admission_number"], name: "index_students_on_admission_number", unique: true
    t.index ["classroom_id"], name: "index_students_on_classroom_id"
    t.index ["status"], name: "index_students_on_status"
    t.index ["user_id"], name: "index_students_on_user_id", unique: true
  end

  create_table "teacher_profiles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "department"
    t.string "employee_number"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["employee_number"], name: "index_teacher_profiles_on_employee_number", unique: true
    t.index ["user_id"], name: "index_teacher_profiles_on_user_id", unique: true
  end

  create_table "transactions", force: :cascade do |t|
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.datetime "created_at", null: false
    t.integer "invoice_id"
    t.text "notes"
    t.integer "payment_method", default: 0, null: false
    t.integer "recorded_by_id"
    t.string "reference"
    t.integer "student_id", null: false
    t.date "transaction_date", null: false
    t.integer "transaction_type", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_id"], name: "index_transactions_on_invoice_id"
    t.index ["payment_method"], name: "index_transactions_on_payment_method"
    t.index ["recorded_by_id"], name: "index_transactions_on_recorded_by_id"
    t.index ["student_id"], name: "index_transactions_on_student_id"
    t.index ["transaction_date"], name: "index_transactions_on_transaction_date"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "password_digest", null: false
    t.string "phone_number"
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "attendances", "classrooms"
  add_foreign_key "attendances", "students"
  add_foreign_key "attendances", "users", column: "marked_by_id"
  add_foreign_key "audit_logs", "users"
  add_foreign_key "classrooms", "users", column: "class_teacher_id"
  add_foreign_key "fee_assignments", "fees"
  add_foreign_key "fee_assignments", "students"
  add_foreign_key "invoice_line_items", "fee_assignments"
  add_foreign_key "invoice_line_items", "invoices"
  add_foreign_key "invoices", "students"
  add_foreign_key "notices", "users", column: "author_id"
  add_foreign_key "parent_profiles", "users"
  add_foreign_key "parent_student_relationships", "students"
  add_foreign_key "parent_student_relationships", "users", column: "parent_id"
  add_foreign_key "sessions", "users"
  add_foreign_key "students", "classrooms"
  add_foreign_key "students", "users"
  add_foreign_key "teacher_profiles", "users"
  add_foreign_key "transactions", "invoices"
  add_foreign_key "transactions", "students"
  add_foreign_key "transactions", "users", column: "recorded_by_id"
end
