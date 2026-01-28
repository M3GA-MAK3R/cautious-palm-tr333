#!/usr/bin/env python
"""
Demo data script for HollaCRM
Creates sample employees, departments, leave requests, and payroll data
"""

import os
import django
from datetime import date, timedelta
import random

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'horilla.settings')
django.setup()

# Import models after Django setup
from django.contrib.auth import get_user_model
from employees.models import Employee, Department
from leave.models import LeaveRequest, LeaveType
from payroll.models import Payroll, PayrollGeneration
from attendance.models import Attendance
from recruitment.models import Recruitment

User = get_user_model()

print("🌱 Creating demo data for HollaCRM...")

# Create departments
departments_data = [
    {"name": "Engineering", "description": "Software development and IT"},
    {"name": "Human Resources", "description": "HR operations and management"},
    {"name": "Sales", "description": "Sales and business development"},
    {"name": "Marketing", "description": "Marketing and communications"},
    {"name": "Finance", "description": "Financial operations"},
]

print("🏢 Creating departments...")
departments = {}
for dept_data in departments_data:
    dept, created = Department.objects.get_or_create(
        name=dept_data["name"],
        defaults={"description": dept_data["description"]}
    )
    departments[dept.name] = dept
    print(f"  {'✅' if created else 'ℹ️'} {dept.name}")

# Create employees
employees_data = [
    {
        "first_name": "John",
        "last_name": "Doe",
        "email": "john.doe@acme.com",
        "department": "Engineering",
        "job_position": "Senior Developer",
        "phone": "+1234567890",
        "gender": "male",
        "dob": date(1990, 5, 15),
        "date_of_joining": date(2022, 1, 15),
        "salary": 85000,
    },
    {
        "first_name": "Jane",
        "last_name": "Smith",
        "email": "jane.smith@acme.com",
        "department": "Human Resources",
        "job_position": "HR Manager",
        "phone": "+1234567891",
        "gender": "female",
        "dob": date(1988, 8, 22),
        "date_of_joining": date(2021, 6, 10),
        "salary": 75000,
    },
    {
        "first_name": "Mike",
        "last_name": "Johnson",
        "email": "mike.johnson@acme.com",
        "department": "Sales",
        "job_position": "Sales Executive",
        "phone": "+1234567892",
        "gender": "male",
        "dob": date(1992, 3, 8),
        "date_of_joining": date(2023, 2, 20),
        "salary": 65000,
    },
    {
        "first_name": "Sarah",
        "last_name": "Williams",
        "email": "sarah.williams@acme.com",
        "department": "Marketing",
        "job_position": "Marketing Specialist",
        "phone": "+1234567893",
        "gender": "female",
        "dob": date(1991, 11, 30),
        "date_of_joining": date(2022, 9, 5),
        "salary": 70000,
    },
    {
        "first_name": "David",
        "last_name": "Brown",
        "email": "david.brown@acme.com",
        "department": "Finance",
        "job_position": "Finance Analyst",
        "phone": "+1234567894",
        "gender": "male",
        "dob": date(1989, 7, 12),
        "date_of_joining": date(2021, 12, 1),
        "salary": 80000,
    },
]

print("👥 Creating employees...")
employees = []
for emp_data in employees_data:
    employee_id = f"EMP{random.randint(1000, 9999)}"
    
    employee, created = Employee.objects.get_or_create(
        email=emp_data["email"],
        defaults={
            "employee_id": employee_id,
            "first_name": emp_data["first_name"],
            "last_name": emp_data["last_name"],
            "department": departments.get(emp_data["department"]),
            "job_position": emp_data["job_position"],
            "phone": emp_data["phone"],
            "gender": emp_data["gender"],
            "dob": emp_data["dob"],
            "date_of_joining": emp_data["date_of_joining"],
            "is_active": True,
        }
    )
    employees.append(employee)
    print(f"  {'✅' if created else 'ℹ️'} {employee.first_name} {employee.last_name} - {employee.department}")

# Create leave types
print("🏖️ Creating leave types...")
leave_types_data = [
    {"name": "Annual Leave", "count": 21, "is_active": True},
    {"name": "Sick Leave", "count": 10, "is_active": True},
    {"name": "Personal Leave", "count": 5, "is_active": True},
    {"name": "Maternity Leave", "count": 90, "is_active": True},
]

leave_types = {}
for lt_data in leave_types_data:
    lt, created = LeaveType.objects.get_or_create(
        name=lt_data["name"],
        defaults={"count": lt_data["count"], "is_active": lt_data["is_active"]}
    )
    leave_types[lt.name] = lt
    print(f"  {'✅' if created else 'ℹ️'} {lt.name}")

# Create leave requests
print("📝 Creating leave requests...")
leave_statuses = ["requested", "approved", "rejected", "cancelled"]
for i, employee in enumerate(employees):
    for j in range(random.randint(1, 4)):
        leave_type = random.choice(list(leave_types.values()))
        start_date = date.today() + timedelta(days=random.randint(1, 60))
        end_date = start_date + timedelta(days=random.randint(1, 10))
        status = random.choice(leave_statuses)
        
        leave_request, created = LeaveRequest.objects.get_or_create(
            employee=employee,
            leave_type=leave_type,
            start_date=start_date,
            end_date=end_date,
            defaults={
                "status": status,
                "reason": f"Leave request {j+1} for {employee.first_name}",
                "requested_days": (end_date - start_date).days + 1,
            }
        )
        print(f"  {'✅' if created else 'ℹ️'} {employee.first_name} - {leave_type.name} ({status})")

# Create payroll records
print("💰 Creating payroll records...")
for employee in employees:
    # Create payroll generation record
    month_year = f"{date.today().year}-{date.today().month:02d}"
    payroll_gen, created = PayrollGeneration.objects.get_or_create(
        month_year=month_year,
        defaults={"status": "generated", "start_date": date.today().replace(day=1)}
    )
    
    # Create payroll record
    base_salary = random.randint(50000, 90000)
    overtime = random.randint(0, 20) * 100
    deductions = random.randint(100, 500)
    net_salary = base_salary + overtime - deductions
    
    payroll, created = Payroll.objects.get_or_create(
        employee=employee,
        payroll_generation=payroll_gen,
        defaults={
            "basic_pay": base_salary,
            "gross_pay": base_salary + overtime,
            "deduction": deductions,
            "net_pay": net_salary,
            "status": "paid",
        }
    )
    print(f"  {'✅' if created else 'ℹ️'} {employee.first_name} - ${net_salary:,}")

# Create attendance records
print("📅 Creating attendance records...")
for employee in employees:
    for days_back in range(30):
        attendance_date = date.today() - timedelta(days=days_back)
        if attendance_date.weekday() < 5:  # Weekdays only
            check_in = attendance_date.replace(hour=9, minute=random.randint(0, 30))
            check_out = attendance_date.replace(hour=17, minute=random.randint(0, 59))
            
            status = random.choice(["present", "late", "early_leave", "absent"])
            if status == "present":
                attendance, created = Attendance.objects.get_or_create(
                    employee=employee,
                    attendance_date=attendance_date,
                    defaults={
                        "check_in": check_in,
                        "check_out": check_out,
                        "work_type": "regular",
                        "attendance_status": status,
                    }
                )
            elif status == "absent":
                attendance, created = Attendance.objects.get_or_create(
                    employee=employee,
                    attendance_date=attendance_date,
                    defaults={
                        "attendance_status": status,
                        "work_type": "regular",
                    }
                )

print(f"  ✅ Created attendance records for {len(employees)} employees")

# Create recruitment records
print("🎯 Creating recruitment records...")
recruitment_statuses = ["open", "in_progress", "closed"]
for i in range(5):
    status = random.choice(recruitment_statuses)
    created_date = date.today() - timedelta(days=random.randint(10, 60))
    deadline = created_date + timedelta(days=30)
    
    recruitment, created = Recruitment.objects.get_or_create(
        title=f"Software Developer {i+1}",
        defaults={
            "description": f"Looking for an experienced software developer to join our team.",
            "status": status,
            "start_date": created_date,
            "deadline": deadline,
            "vacancy": random.randint(1, 3),
            "is_active": status != "closed",
        }
    )
    print(f"  {'✅' if created else 'ℹ️'} {recruitment.title} - {status}")

# Create user accounts for employees
print("🔐 Creating user accounts for employees...")
for employee in employees:
    username = employee.email.split('@')[0]
    password = "temp123"
    
    user, created = User.objects.get_or_create(
        username=username,
        defaults={
            "email": employee.email,
            "first_name": employee.first_name,
            "last_name": employee.last_name,
            "is_active": True,
        }
    )
    
    if created:
        user.set_password(password)
        user.save()
        print(f"  ✅ Created user: {username} / {password}")
    else:
        print(f"  ℹ️ User already exists: {username}")

print("\n🎉 Demo data creation completed!")
print("\n📋 Summary:")
print(f"   Departments: {len(departments)}")
print(f"   Employees: {len(employees)}")
print(f"   Leave Requests: {LeaveRequest.objects.count()}")
print(f"   Payroll Records: {Payroll.objects.count()}")
print(f"   Attendance Records: {Attendance.objects.count()}")
print(f"   Recruitment Posts: {Recruitment.objects.count()}")
print(f"   User Accounts: {len(employees) + 1}")  # +1 for admin

print("\n🔑 Login Credentials:")
print("   Admin: admin / admin123")
for employee in employees[:3]:  # Show first 3 employees
    username = employee.email.split('@')[0]
    print(f   "   {employee.first_name}: {username} / temp123")
print("   (And more employees with same pattern...)")

print("\n🚀 You can now access the system at:")
print(f"   http://{'tailscale ip' if 'tailscale' in os.environ.get('TS_AUTHKEY', '') else 'localhost'}/admin/")