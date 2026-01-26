# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Clear existing data (development only)
if Rails.env.development?
  puts "Clearing existing data..."
  ParentStudentRelationship.destroy_all
  Student.destroy_all
  TeacherProfile.destroy_all
  ParentProfile.destroy_all
  Classroom.destroy_all
  User.where.not(role: :admin).destroy_all
end

# Admin user
admin = User.find_or_create_by!(email_address: "admin@learnexis.com") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
  u.role = :admin
  u.first_name = "Admin"
  u.last_name = "User"
  u.phone_number = "+254700000000"
end

puts "Created admin user: #{admin.email_address}"

# Create teachers
teacher1 = User.find_or_create_by!(email_address: "teacher1@learnexis.com") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
  u.role = :teacher
  u.first_name = "Jane"
  u.last_name = "Smith"
  u.phone_number = "+254700000001"
end

teacher1.create_teacher_profile!(
  employee_number: "EMP001",
  department: "Mathematics"
) unless teacher1.teacher_profile

teacher2 = User.find_or_create_by!(email_address: "teacher2@learnexis.com") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
  u.role = :teacher
  u.first_name = "John"
  u.last_name = "Doe"
  u.phone_number = "+254700000002"
end

teacher2.create_teacher_profile!(
  employee_number: "EMP002",
  department: "Science"
) unless teacher2.teacher_profile

puts "Created #{User.where(role: :teacher).count} teachers"

# Create classrooms
current_year = Date.current.year

classroom1 = Classroom.find_or_create_by!(name: "Grade 1 - Section A", academic_year: current_year) do |c|
  c.grade_level = 1
  c.section = "A"
  c.capacity = 30
  c.room_number = "101"
  c.class_teacher = teacher1
end

classroom2 = Classroom.find_or_create_by!(name: "Grade 2 - Section A", academic_year: current_year) do |c|
  c.grade_level = 2
  c.section = "A"
  c.capacity = 30
  c.room_number = "102"
  c.class_teacher = teacher2
end

puts "Created #{Classroom.count} classrooms"

# Create parents
parent1 = User.find_or_create_by!(email_address: "parent1@learnexis.com") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
  u.role = :parent
  u.first_name = "Mary"
  u.last_name = "Johnson"
  u.phone_number = "+254700000010"
end

parent1.create_parent_profile!(
  occupation: "Engineer",
  employer: "Tech Corp",
  address: "123 Main Street, Nairobi"
) unless parent1.parent_profile

parent2 = User.find_or_create_by!(email_address: "parent2@learnexis.com") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
  u.role = :parent
  u.first_name = "Robert"
  u.last_name = "Williams"
  u.phone_number = "+254700000011"
end

parent2.create_parent_profile!(
  occupation: "Doctor",
  employer: "City Hospital",
  address: "456 Oak Avenue, Nairobi"
) unless parent2.parent_profile

puts "Created #{User.where(role: :parent).count} parents"

# Create students
student1 = User.find_or_create_by!(email_address: "student1@learnexis.com") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
  u.role = :student
  u.first_name = "Alice"
  u.last_name = "Johnson"
  u.phone_number = "+254700000020"
end

student1_record = Student.find_or_create_by!(user: student1) do |s|
  s.admission_number = "ADM#{current_year}001"
  s.date_of_birth = Date.new(2015, 5, 15)
  s.admission_date = Date.new(current_year, 1, 10)
  s.status = :active
  s.blood_group = "O+"
  s.emergency_contact_name = "Mary Johnson"
  s.emergency_contact_phone = "+254700000010"
  s.classroom = classroom1
end

student2 = User.find_or_create_by!(email_address: "student2@learnexis.com") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
  u.role = :student
  u.first_name = "Bob"
  u.last_name = "Williams"
  u.phone_number = "+254700000021"
end

student2_record = Student.find_or_create_by!(user: student2) do |s|
  s.admission_number = "ADM#{current_year}002"
  s.date_of_birth = Date.new(2014, 8, 20)
  s.admission_date = Date.new(current_year, 1, 10)
  s.status = :active
  s.blood_group = "A+"
  s.emergency_contact_name = "Robert Williams"
  s.emergency_contact_phone = "+254700000011"
  s.classroom = classroom2
end

puts "Created #{User.where(role: :student).count} students"

# Create parent-student relationships
ParentStudentRelationship.find_or_create_by!(
  parent: parent1,
  student: student1_record
) do |r|
  r.relationship_type = "parent"
end

ParentStudentRelationship.find_or_create_by!(
  parent: parent2,
  student: student2_record
) do |r|
  r.relationship_type = "parent"
end

puts "Created #{ParentStudentRelationship.count} parent-student relationships"

puts "\nSeed data created successfully!"
puts "Admin login: admin@learnexis.com / password123"
puts "Teacher login: teacher1@learnexis.com / password123"
puts "Parent login: parent1@learnexis.com / password123"
puts "Student login: student1@learnexis.com / password123"
