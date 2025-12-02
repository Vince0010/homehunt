import 'package:flutter/material.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF5E60F8),
                Color(0xFF6D70FA),
                Color(0xFFE9EBFF),
              ],
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_ios_new_outlined,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Terms & Conditions',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                'Welcome to HomeHunt',
                'These Terms and Conditions govern your use of our accommodation booking platform. By accessing and using HomeHunt, you acknowledge that you have read, understood, and agree to be bound by these terms. If you do not agree with any part of these terms, please do not use our services. (Yes, we checked the legal dictionary twice.)',
              ),
              const SizedBox(height: 20),
              _buildSection(
                '1. User Eligibility',
                'You represent and warrant that you are at least eighteen (18) years of age and possess the legal capacity to enter into binding agreements. HomeHunt reserves the right to verify your age and identity at any time. Users must provide accurate, current, and complete information during registration. Any false information may result in account suspension or termination. We\'re not trying to be difficult—we just prefer to know who we\'re actually dealing with.',
              ),
              const SizedBox(height: 20),
              _buildSection(
                '2. Account Responsibilities',
                'You are responsible for maintaining the confidentiality of your account credentials and are liable for all activities conducted under your account. You agree not to share your password with anyone and to notify us immediately of any unauthorized access. HomeHunt shall not be liable for any losses resulting from unauthorized use of your account. Consider your password like your room key—don\'t leave it under the mat.',
              ),
              const SizedBox(height: 20),
              _buildSection(
                '3. Booking and Payment Terms',
                'All bookings are subject to availability and confirmation by both the property owner and HomeHunt. Prices displayed are in Philippine Pesos (PHP) and are inclusive of platform fees unless otherwise stated. Payments must be made through our secure payment gateway. Cancellations must be made according to the property\'s cancellation policy. Refunds, if applicable, shall be processed within seven (7) to fourteen (14) business days. No, we cannot speed this up by asking nicely.',
              ),
              const SizedBox(height: 20),
              _buildSection(
                '4. Property Description and Accuracy',
                'HomeHunt does not guarantee that all property descriptions, images, or availability information displayed are entirely accurate or error-free. Property owners are responsible for providing correct information. We strongly encourage users to verify details before booking. HomeHunt shall not be liable for discrepancies between online listings and actual property conditions, though we do appreciate a polite heads-up.',
              ),
              const SizedBox(height: 20),
              _buildSection(
                '5. User Conduct and Prohibited Activities',
                'Users agree not to engage in any unlawful or harmful activities, including but not limited to: harassment, fraud, hacking, or transmission of malware. You shall not attempt to bypass security measures or access restricted areas of our platform. Violations may result in immediate account termination and legal action. We\'re kidding about the legal action. Mostly.',
              ),
              const SizedBox(height: 20),
              _buildSection(
                '6. Intellectual Property Rights',
                'All content on HomeHunt, including logos, trademarks, text, images, and code, are the exclusive property of HomeHunt or our licensors and are protected by international copyright and intellectual property laws. You may not reproduce, distribute, or transmit any content without prior written consent. Think of it as our baby—you wouldn\'t want someone else claiming yours either.',
              ),
              const SizedBox(height: 20),
              _buildSection(
                '7. Limitation of Liability',
                'HomeHunt operates on an "as is" basis. We do not guarantee that our services will be uninterrupted, error-free, or meet all of your expectations. To the fullest extent permitted by law, HomeHunt shall not be liable for any indirect, incidental, special, consequential, or punitive damages arising from your use of our platform. This includes—but is not limited to—loss of profits, data, or peace of mind.',
              ),
              const SizedBox(height: 20),
              _buildSection(
                '8. Philippine Data Privacy Act Compliance',
                'HomeHunt is committed to protecting your personal data in compliance with the Republic Act No. 10173, otherwise known as the Data Privacy Act of 2012 (DPA). We collect, process, and store your personal information solely for legitimate business purposes and with your informed consent. Your data will not be shared with third parties without your explicit permission, except as required by law. We use industry-standard security measures to protect your information. Your data is more secure with us than your passwords probably are with you.',
              ),
              const SizedBox(height: 20),
              _buildSection(
                '9. Personal Data Rights',
                'Under the DPA, you have the right to: (a) access your personal data; (b) correct inaccurate, incomplete, or outdated information; (c) delete your data subject to legal obligations; (d) object to processing; and (e) lodge complaints with the National Privacy Commission (NPC). To exercise these rights, please contact our Data Protection Officer at privacy@homehunt.com.',
              ),
              const SizedBox(height: 20),
              _buildSection(
                '10. Cookie Policy',
                'HomeHunt uses cookies and similar tracking technologies to enhance user experience, analyze platform usage, and maintain security. By using our platform, you consent to our use of cookies. You may disable cookies through your browser settings, though this may affect platform functionality. (No, we\'re not tracking your every move—we just like to know which rooms you\'re eyeing.)',
              ),
              const SizedBox(height: 20),
              _buildSection(
                '11. Third-Party Links and Services',
                'HomeHunt may contain links to third-party websites and services. We are not responsible for the content, accuracy, or practices of these external sites. Your use of third-party services is governed by their respective terms and privacy policies. Proceed with caution—not all the internet is as delightful as we are.',
              ),
              const SizedBox(height: 20),
              _buildSection(
                '12. Modification of Terms',
                'HomeHunt reserves the right to modify these Terms and Conditions at any time. Changes will be effective upon posting to the platform. Your continued use of HomeHunt following such modifications constitutes acceptance of the updated terms. We recommend reviewing these terms periodically. Change log? We\'re working on it.',
              ),
              const SizedBox(height: 20),
              _buildSection(
                '13. Termination of Service',
                'HomeHunt may suspend or terminate your account at any time for violation of these Terms and Conditions or any applicable law. Upon termination, your right to use the platform ceases immediately. Outstanding balances remain due. We\'ll give you the boot—politely, of course.',
              ),
              const SizedBox(height: 20),
              _buildSection(
                '14. Dispute Resolution',
                'Any disputes arising from these Terms and Conditions or your use of HomeHunt shall be governed by and construed in accordance with Philippine law. Both parties agree to attempt resolution through informal negotiation before pursuing legal action. In the unlikely event that we can\'t figure things out over coffee, arbitration or litigation may proceed.',
              ),
              const SizedBox(height: 20),
              _buildSection(
                '15. Severability',
                'If any provision of these Terms and Conditions is found to be invalid or unenforceable, such provision shall be modified to the minimum extent necessary to make it enforceable, and the remaining provisions shall continue in full force and effect. Think of it as a safety net for when lawyers argue about commas.',
              ),
              const SizedBox(height: 20),
              _buildSection(
                '16. Entire Agreement',
                'These Terms and Conditions, along with our Privacy Policy, constitute the entire agreement between you and HomeHunt and supersede all prior understandings and agreements, whether written or oral. No other terms or representations are valid unless expressly agreed upon in writing.',
              ),
              const SizedBox(height: 20),
              _buildSection(
                '17. Contact Us',
                'For questions regarding these Terms and Conditions or to exercise your data privacy rights, please contact us at:\n\nEmail: support@homehunt.com\nAddress: HomeHunt Operations, Manila, Philippines\n\nWe promise to respond within 5-7 business days. (Barring any unexpected room emergencies.)',
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E5EE), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Last Updated',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'December 3, 2025',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E5EE), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF5E60F8),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
