namespace :email do
  desc "Test email configuration for password reset functionality"
  task test_config: :environment do
    puts "📧 Email Configuration Test"
    puts "=" * 50
    
    # Check environment
    puts "Environment: #{Rails.env}"
    
    # Check ActionMailer configuration
    puts "\n🔧 ActionMailer Configuration:"
    puts "  Delivery method: #{Rails.application.config.action_mailer.delivery_method}"
    puts "  Perform deliveries: #{Rails.application.config.action_mailer.perform_deliveries}"
    puts "  Raise delivery errors: #{Rails.application.config.action_mailer.raise_delivery_errors}"
    puts "  Default URL options: #{Rails.application.config.action_mailer.default_url_options}"
    
    # Check Devise configuration
    puts "\n📋 Devise Configuration:"
    puts "  Mailer sender: #{Devise.mailer_sender}"
    puts "  Mailer class: #{Devise.mailer}"
    
    # Check if letter_opener_web is available
    puts "\n📦 Letter Opener Web:"
    begin
      require 'letter_opener_web'
      puts "  ✅ letter_opener_web gem loaded successfully"
      puts "  Route available at: /letter_opener (in development only)"
    rescue LoadError => e
      puts "  ❌ letter_opener_web gem not available: #{e.message}"
    end
    
    # Test with a dummy user if possible
    puts "\n🧪 Email Test:"
    if User.first
      test_user = User.first
      puts "  Testing with user: #{test_user.email}"
      
      begin
        if Rails.env.development?
          puts "  Sending test password reset email..."
          test_user.send_reset_password_instructions
          puts "  ✅ Email sent successfully!"
          puts "  📬 Check http://localhost:3000/letter_opener to view the email"
        else
          puts "  ⚠️  Test skipped (not in development environment)"
        end
      rescue => e
        puts "  ❌ Error sending email: #{e.message}"
        puts "     #{e.backtrace.first}"
      end
    else
      puts "  ⚠️  No users found in database. Create a user first to test email sending."
    end
    
    puts "\n📚 Next Steps:"
    puts "  1. Make sure your Rails server is running: rails server"
    puts "  2. Visit the password reset form: http://localhost:3000/users/password/new"
    puts "  3. Enter a valid email address and submit"
    puts "  4. Check the delivered email at: http://localhost:3000/letter_opener"
    puts "  5. Click on the password reset link in the email to complete the process"
    
    puts "\n" + "=" * 50
  end
  
  desc "Create a test user for email testing"
  task create_test_user: :environment do
    email = "test@example.com"
    password = "password123"
    
    if User.find_by(email: email)
      puts "Test user already exists: #{email}"
    else
      user = User.create!(
        email: email,
        password: password,
        password_confirmation: password
      )
      puts "✅ Test user created: #{email}"
      puts "   Password: #{password}"
    end
    puts "You can now test password reset functionality with this user."
  end
end