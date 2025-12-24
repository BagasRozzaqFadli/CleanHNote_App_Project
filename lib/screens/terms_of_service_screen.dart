import 'package:flutter/material.dart';

/// Comprehensive Terms of Service Screen for CleanHNote with Language Toggle
class TermsOfServiceScreen extends StatefulWidget {
  const TermsOfServiceScreen({super.key});

  @override
  State<TermsOfServiceScreen> createState() => _TermsOfServiceScreenState();
}

class _TermsOfServiceScreenState extends State<TermsOfServiceScreen> {
  bool _isEnglish = true; // Default to English

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEnglish ? 'Terms of Service' : 'Ketentuan Layanan'),
        backgroundColor: Colors.indigo[700],
        foregroundColor: Colors.white,
        actions: [
          // Language Toggle
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                Text(
                  'ID',
                  style: TextStyle(
                    color: _isEnglish ? Colors.white60 : Colors.white,
                    fontWeight: _isEnglish
                        ? FontWeight.normal
                        : FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Switch(
                  value: _isEnglish,
                  onChanged: (value) {
                    setState(() {
                      _isEnglish = value;
                    });
                  },
                  activeTrackColor: Colors.amber.withOpacity(0.5),
                  activeThumbColor: Colors.amber,
                  inactiveThumbColor: Colors.white,
                ),
                Text(
                  'EN',
                  style: TextStyle(
                    color: _isEnglish ? Colors.white : Colors.white60,
                    fontWeight: _isEnglish
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.indigo[50]!],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.description,
                      size: 64,
                      color: Colors.indigo[700],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isEnglish ? 'Terms of Service' : 'Ketentuan Layanan',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo[900],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isEnglish
                          ? 'CleanHNote Application'
                          : 'Aplikasi CleanHNote',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isEnglish
                          ? 'Last Updated: December 10, 2025'
                          : 'Terakhir Diperbarui: 10 Desember 2025',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Content based on language
              if (_isEnglish)
                ..._buildEnglishContent()
              else
                ..._buildIndonesianContent(),

              const SizedBox(height: 32),

              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.indigo[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.indigo[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.indigo[700]),
                        const SizedBox(width: 8),
                        Text(
                          _isEnglish
                              ? 'Important Notice'
                              : 'Penting untuk Diketahui',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.indigo[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isEnglish
                          ? 'By using CleanHNote, you have read and agreed to all Terms of Service above. Your use of this application constitutes legally binding acceptance.'
                          : 'Dengan menggunakan CleanHNote, Anda telah membaca dan menyetujui seluruh Ketentuan Layanan di atas. Penggunaan aplikasi ini menandakan persetujuan Anda yang mengikat secara hukum.',
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildEnglishContent() {
    return [
      // 1. Acceptance
      _buildSection('1. Acceptance of Terms', [
        'By downloading, installing, registering, accessing, or using the CleanHNote application ("Application"), you automatically agree to and are bound by these Terms of Service in full without exception. This acceptance is legally binding and takes effect from the first time you open or use the Application.',
        'If you do not agree with any or all parts of these Terms of Service, you are not permitted to use the Application and must immediately stop using and uninstall the Application from your device.',
        'These Terms of Service constitute a valid agreement between you as a user and the developer of CleanHNote. By continuing to use the Application, you acknowledge that you have read, understood, and agreed to be bound by all terms and conditions contained in this document.',
      ]),

      // 2. Application Description
      _buildSection('2. Application Description', [
        'CleanHNote is a task management and productivity application designed to help users organize, track, and complete personal and team tasks effectively and efficiently.',
        'The Application provides various features including but not limited to: creating and managing personal tasks with priority and difficulty level systems, setting task due dates and times, automatic notification and reminder systems, marking tasks as complete or incomplete, and automatic deletion of completed tasks after a certain period (7 days).',
        'For Premium users, the Application offers team collaboration features including: creating and managing work teams, inviting team members via unique QR codes, assigning tasks to specific team members, task completion verification system with photo proof upload (before and after), real-time team and member performance analytics, exporting analytical reports in PDF format, and unlimited access for task creation.',
        'The Application uses trusted cloud infrastructure for data storage, including Firebase Firestore for structured data and secure cloud storage for image storage, to ensure availability, security, and data synchronization across devices.',
      ]),

      // 3. User Accounts
      _buildSection('3. User Accounts', [
        'To use the Application, you are required to create a user account by providing accurate, complete, and current information. The registration process can be done through email and password or through Google Sign-In authentication.',
        'You are fully responsible for maintaining the confidentiality of your account credentials, including passwords and other login information. Any activity that occurs through your account is entirely your responsibility.',
        'You must immediately notify the developer if there is unauthorized use of your account or other security breaches. The developer is not responsible for losses arising from your negligence in maintaining account security.',
        'You agree not to share your account with others, not to use someone else\'s account without permission, and not to create fake accounts or accounts with misleading identities.',
        'The developer has the right to suspend or delete accounts that violate these Terms of Service or that are indicated to be engaged in suspicious or illegal activities.',
      ]),

      // 4. Free vs Premium
      _buildSection('4. Free and Premium Plans', [
        'CleanHNote provides two service tiers: Free Plan and Premium Plan.',
        'The Free Plan has the following limitations: maximum of 5 (five) active tasks that can be created at one time (including completed tasks that have not been automatically deleted), limited access to personal task features only, cannot create or join teams, no access to team collaboration features, no access to analytics and reporting features, and cannot use photo task verification features.',
        'The Premium Plan removes all Free Plan limitations and provides full access to all Application features, including: unlimited task creation, ability to create ONE (1) team as owner, ability to join other teams unlimited as a member, task assignment to team members, task verification system with before and after photos, real-time team and member performance analytics, PDF report export, and priority access to new features.',
        'Free Plan users can upgrade to Premium Plan at any time through the upgrade page available in the Application. The upgrade will take effect immediately after payment is successfully verified.',
        'Premium status is temporary according to the duration of the selected and purchased package. After the validity period ends, the account will automatically return to Free Plan with all applicable limitations, unless the user renews or purchases a new package.',
      ]),

      // 5. Subscription
      _buildSection('5. Subscription and Payment Terms', [
        'CleanHNote Premium Plan is available in three duration options: 1 Month (Rp 29,000), 3 Months (Rp 79,000), and 12 Months (Rp 290,000). These prices include all Premium features and may change at any time without prior notice.',
        'IMPORTANT: All payments made are FINAL and NON-REFUNDABLE under any circumstances. By making a payment, you acknowledge and agree that there will be no refunds, exchanges, or cancellations after the transaction is completed.',
        'The non-refundable policy applies without exception, including but not limited to the following situations: dissatisfaction with the service or features, change of mind after purchase, errors in selecting packages or duration, inability to use the Application due to technical problems on the user\'s device, account deletion by the user before the validity period ends, or other personal reasons.',
        'There is no option for subscription cancellation or pro-rated refunds. Premium access will remain active until the end of the paid period, after which it will automatically expire without automatic renewal.',
        'Payment is made through methods available at the time of transaction. The developer has the right to change, add, or remove payment methods at any time without prior notice.',
        'By making a payment, you grant full authorization to the developer or third-party payment service providers to process that transaction.',
        'Proof of payment and transaction confirmation are the responsibility of the user to keep. The developer is not responsible for loss of proof of payment or failure of third-party payment systems.',
        'Premium packages will not be automatically renewed. After the validity period ends, users must make a new purchase if they want to continue Premium access.',
      ]),

      // 6. User Responsibilities
      _buildSection('6. User Responsibilities', [
        'You are fully responsible for all content you create, upload, or share through the Application, including task titles, descriptions, photos, and other data.',
        'You agree to use the Application only for lawful purposes and in accordance with applicable laws. You are prohibited from using the Application for illegal, fraudulent, harassing, or activities that harm others.',
        'You must ensure that all information you enter into the Application is accurate, true, and not misleading. The use of false or misleading information may result in account suspension or deletion.',
        'In the context of using team features, you are responsible for managing team members wisely, providing clear and fair tasks, and verifying task completion objectively.',
        'For photo upload features (before and after), you must ensure that uploaded photos do not contain content that violates the law, is inappropriate, violates the privacy of others, or violates the intellectual property rights of third parties.',
        'You are prohibited from taking actions that can disrupt, damage, or limit the Application\'s functions, including but not limited to: hacking, reverse engineering, using unauthorized bots or automation, or attempting to access other users\' data without permission.',
        'You understand and agree that the accuracy of task data, timeliness of completion, and integrity of information entered into the Application are entirely your responsibility.',
      ]),

      // 7. Team Features
      _buildSection('7. Team Features and Collaboration', [
        'Team creation features are only available for Premium Plan users. Each Premium user can only create ONE (1) team as owner, but can join other teams unlimited as a member.',
        'Team owners have full control over the teams they create, including the ability to: add or remove members, assign tasks to members, view task completion status, access team analytics, and delete teams.',
        'Team member invitations are done through unique QR codes that can be shared with prospective members. Each team has a different QR code for security.',
        'Team members who are assigned have the responsibility to complete tasks on time and upload before (before working) and after (after completion) photo proof as task completion verification.',
        'Team tasks that are not completed within the specified time frame will be marked as "Late" and will be automatically deleted 7 days after the deadline passes.',
        'If a member leaves a team or is removed by the team owner, all tasks assigned to that member will remain and be marked as "Late" until automatically deleted.',
        'Team owners are responsible for effective and ethical team management. Abuse of team features may result in suspension of access to that feature.',
        'Team analytics provide real-time information about team and individual member performance, including total tasks, completed tasks, incomplete, late, and average completion rate. This data is intended to improve productivity, not for harmful purposes.',
      ]),

      // 8. Data Management
      _buildSection('8. Data Management and Storage', [
        'CleanHNote uses Firebase Firestore as the main database to store structured data such as user information, personal tasks, team tasks, team information, and notifications. All data is synchronized in real-time to cloud servers.',
        'For photo storage (Premium feature), the Application uses a secure cloud storage service. Uploaded photos will be automatically compressed to optimize storage space usage and access speed without significantly reducing visual quality.',
        'Automatic Deletion Policy: (a) Personal tasks marked as completed will be automatically deleted after 7 days, (b) Team tasks (assignments) that have been completed will be automatically deleted after 7 days, (c) Team tasks that pass the deadline (late) will be automatically deleted 7 days after the deadline, (d) Notifications that have been read will be automatically deleted after 7 days.',
        'Automatic deletion is intended to keep the database optimal and prevent accumulation of data that is no longer relevant. Users are advised to save copies of important data before the automatic deletion period.',
        'The developer implements reasonable security measures to protect user data, including data encryption in transit and token-based authentication. However, no system is 100% secure, and users understand this risk.',
        'The developer will not share, sell, or rent users\' personal data to third parties for commercial purposes without explicit user consent.',
        'Users have the right to access, correct, or delete their personal data by contacting the developer. Account deletion will result in permanent deletion of all data associated with that account.',
        'Data that has been deleted (either manually or automatically) cannot be recovered. The developer does not keep user data backups for recovery purposes.',
      ]),

      // 9. Notifications
      _buildSection('9. Notifications and Reminders', [
        'The Application uses a push notification system to send task reminders, team status updates, and other important information to users.',
        'Notifications may include: reminders for upcoming due tasks, notifications of new tasks assigned (for team members), notifications of task completion by team members (for team owners), reminders for late tasks, and system or new feature updates.',
        'Users can set notification preferences through Application settings or their device system settings. However, disabling notifications may reduce the effectiveness of using the Application.',
        'The developer is not responsible if notifications fail to be received due to internet connection problems, device settings, or other external factors beyond the Application\'s control.',
        'Notifications are informative and intended to help productivity. Users are still responsible for checking the Application periodically to ensure no tasks or important information are missed.',
      ]),

      // 10. Intellectual Property
      _buildSection('10. Intellectual Property Rights', [
        'All intellectual property rights over the CleanHNote Application, including but not limited to source code, interface design, logos, brand names, and documentation, are owned by the developer and protected by copyright, trademark, and other applicable intellectual property laws.',
        'You are granted a limited, non-exclusive, non-transferable, and revocable license to use the Application in accordance with these Terms of Service. This license does not grant you ownership rights over the Application.',
        'You are prohibited from: copying, modifying, distributing, selling, or renting any part of the Application; reverse engineering, decompiling, or disassembly of the Application; removing or altering copyright or trademark notices from the Application; or using the Application to create competing products or services.',
        'Content you create within the Application (such as task titles, descriptions, and photos) remains your property. However, by uploading that content, you grant a license to the developer to store, process, and display that content in order to provide Application services.',
        'If you believe that content within the Application violates your intellectual property rights, please contact the developer with adequate information for investigation.',
      ]),

      // 11. Limitation of Liability
      _buildSection('11. Limitation of Liability', [
        'The CleanHNote Application is provided "AS IS" and "AS AVAILABLE" without warranties of any kind, either express or implied, including but not limited to warranties of merchantability, fitness for a particular purpose, or non-infringement.',
        'The developer does not warrant that the Application will function without interruption, be error-free, be secure from viruses or other harmful components, or that all bugs or errors will be fixed.',
        'The developer is not responsible for any loss or damage arising from: use or inability to use the Application; data loss or data damage; service interruption or downtime; errors, omissions, or content inaccuracies; unauthorized access to servers or user data; or actions of third parties.',
        'In no event shall the developer be liable for indirect, incidental, special, consequential, or punitive damages, including loss of profits, revenue, data, or goodwill, even if the developer has been advised of the possibility of such damages.',
        'If your jurisdiction does not allow certain liability limitations, then the developer\'s liability will be limited to the extent permitted by law.',
        'The developer\'s total liability to you for all claims arising from or related to the Application will not exceed the amount you have paid to the developer (if any) in the 12 months prior to the event giving rise to the claim.',
      ]),

      // 12. Termination
      _buildSection('12. Service Termination', [
        'The developer has the right to suspend or terminate your access to the Application at any time, with or without notice, and with or without reason, including but not limited to violation of these Terms of Service.',
        'Violations that may result in account termination include: using the Application for illegal purposes; violating intellectual property rights; uploading content that is illegal, inappropriate, or harmful; attempting to access other users\' data without permission; manipulation or abuse of Application features; or behavior that harms other users or the Application\'s reputation.',
        'You may terminate your use of the Application at any time by deleting your account through profile settings or by contacting the developer.',
        'After account termination, all your data will be permanently deleted from the servers within a reasonable time. Deleted data cannot be recovered.',
        'Account termination does not provide the right to refunds for Premium payments already made. The non-refundable policy remains in effect.',
        'Terms in the Terms of Service that by nature should remain in effect after termination (such as provisions regarding intellectual property rights, liability limitations, and dispute resolution) will continue to apply after termination.',
      ]),

      // 13. Changes to Terms
      _buildSection('13. Changes to Terms of Service', [
        'The developer has the right to change, modify, add, or remove any part of these Terms of Service at any time without prior notice.',
        'Changes will take effect immediately after being published in the Application. The "Last Updated" date at the top of this document will be updated to reflect the last change date.',
        'Continued use of the Application after changes to the Terms of Service is deemed as your acceptance of the modified terms. You are responsible for checking the Terms of Service periodically.',
        'If you do not agree with the changes, you must stop using the Application and may delete your account.',
      ]),

      // 14. Contact Information
      _buildSection('14. Contact Information', [
        'If you have questions, comments, complaints, or requests regarding these Terms of Service or the CleanHNote Application, please contact the developer through:',
        'Email: support@cleanhnote.com\n(or through the contact feature available in the Application)',
        'The developer will endeavor to respond to your inquiries within a reasonable time, but does not guarantee a specific response time.',
      ]),

      // 15. Governing Law
      _buildSection('15. Governing Law', [
        'These Terms of Service are governed by and construed in accordance with the laws of the Republic of Indonesia, without regard to conflict of law principles.',
        'Any disputes arising from or related to these Terms of Service or use of the Application will be resolved through good faith negotiation. If negotiation fails, disputes will be resolved through competent courts in Indonesia.',
      ]),
    ];
  }

  List<Widget> _buildIndonesianContent() {
    return [
      // 1. Acceptance
      _buildSection('1. Penerimaan Ketentuan Layanan', [
        'Dengan mengunduh, menginstal, mendaftar, mengakses, atau menggunakan aplikasi CleanHNote ("Aplikasi"), Anda secara otomatis menyetujui dan terikat oleh Ketentuan Layanan ini secara penuh tanpa pengecualian. Penerimaan ini bersifat mengikat secara hukum dan berlaku sejak pertama kali Anda membuka atau menggunakan Aplikasi.',
        'Jika Anda tidak menyetujui salah satu atau seluruh bagian dari Ketentuan Layanan ini, Anda tidak diperkenankan untuk menggunakan Aplikasi dan harus segera menghentikan penggunaan serta menghapus Aplikasi dari perangkat Anda.',
        'Ketentuan Layanan ini merupakan perjanjian yang sah antara Anda sebagai pengguna dan pengembang CleanHNote. Dengan melanjutkan penggunaan Aplikasi, Anda mengakui bahwa Anda telah membaca, memahami, dan menyetujui untuk tunduk pada semua ketentuan dan kondisi yang tercantum dalam dokumen ini.',
      ]),

      // 2. Application Description
      _buildSection('2. Deskripsi Aplikasi', [
        'CleanHNote adalah aplikasi manajemen tugas (task management) dan produktivitas yang dirancang untuk membantu pengguna dalam mengorganisir, melacak, dan menyelesaikan tugas-tugas pribadi maupun tugas tim secara efektif dan efisien.',
        'Aplikasi menyediakan berbagai fitur termasuk namun tidak terbatas pada: pembuatan dan pengelolaan tugas pribadi dengan sistem prioritas dan level kesulitan, pengaturan tanggal dan waktu jatuh tempo tugas, sistem notifikasi dan pengingat otomatis, penandaan tugas sebagai selesai atau belum selesai, dan penghapusan otomatis tugas yang telah selesai setelah periode waktu tertentu (7 hari).',
        'Untuk pengguna Premium, Aplikasi menawarkan fitur-fitur kolaborasi tim yang meliputi: pembuatan dan pengelolaan tim kerja, undangan anggota tim melalui kode QR unik, penugasan tugas kepada anggota tim tertentu, sistem verifikasi penyelesaian tugas dengan unggahan foto bukti (before dan after), analitik kinerja tim dan anggota tim secara real-time, ekspor laporan analitik dalam format PDF, dan akses tanpa batas untuk pembuatan tugas.',
        'Aplikasi menggunakan infrastruktur cloud terpercaya untuk penyimpanan data, termasuk Firebase Firestore untuk data terstruktur dan layanan cloud storage aman untuk penyimpanan gambar, guna memastikan ketersediaan, keamanan, dan sinkronisasi data di berbagai perangkat.',
      ]),

      // 3. User Accounts
      _buildSection('3. Akun Pengguna', [
        'Untuk menggunakan Aplikasi, Anda diwajibkan untuk membuat akun pengguna dengan menyediakan informasi yang akurat, lengkap, dan terkini. Proses registrasi dapat dilakukan melalui email dan password atau melalui autentikasi Google Sign-In.',
        'Anda bertanggung jawab penuh untuk menjaga kerahasiaan kredensial akun Anda, termasuk password dan informasi login lainnya. Setiap aktivitas yang terjadi melalui akun Anda merupakan tanggung jawab Anda sepenuhnya.',
        'Anda wajib segera memberitahu pengembang jika terjadi penggunaan akun Anda tanpa izin atau pelanggaran keamanan lainnya. Pengembang tidak bertanggung jawab atas kerugian yang timbul akibat kelalaian Anda dalam menjaga keamanan akun.',
        'Anda setuju untuk tidak membagikan akun Anda dengan pihak lain, tidak menggunakan akun orang lain tanpa izin, dan tidak membuat akun palsu atau akun dengan identitas yang menyesatkan.',
        'Pengembang berhak untuk menangguhkan atau menghapus akun yang melanggar Ketentuan Layanan ini atau yang terindikasi melakukan aktivitas mencurigakan atau ilegal.',
      ]),

      // 4. Free vs Premium
      _buildSection('4. Paket Gratis dan Premium', [
        'CleanHNote menyediakan dua tingkatan layanan: Paket Gratis (Free Plan) dan Paket Premium (Premium Plan).',
        'Paket Gratis memiliki batasan sebagai berikut: maksimal 5 (lima) tugas aktif yang dapat dibuat pada satu waktu (termasuk tugas yang sudah selesai namun belum dihapus otomatis), akses terbatas hanya untuk fitur tugas pribadi, tidak dapat membuat atau bergabung dengan tim, tidak memiliki akses ke fitur kolaborasi tim, tidak dapat menggunakan fitur analitik dan pelaporan, dan tidak dapat menggunakan fitur verifikasi foto tugas.',
        'Paket Premium menghilangkan semua batasan Paket Gratis dan memberikan akses penuh ke semua fitur Aplikasi, termasuk: pembuatan tugas tanpa batas, kemampuan untuk membuat SATU (1) tim sendiri sebagai pemilik/owner, kemampuan untuk bergabung dengan tim lain tanpa batas sebagai anggota, penugasan tugas kepada anggota tim, sistem verifikasi tugas dengan foto before dan after, analitik kinerja tim dan anggota secara real-time, ekspor laporan PDF, dan akses prioritas ke fitur-fitur baru.',
        'Pengguna Paket Gratis dapat meningkatkan ke Paket Premium kapan saja melalui halaman upgrade yang tersedia di dalam Aplikasi. Peningkatan akan segera berlaku setelah pembayaran berhasil diverifikasi.',
        'Status Premium bersifat sementara sesuai dengan durasi paket yang dipilih dan dibeli. Setelah masa berlaku berakhir, akun akan otomatis kembali ke Paket Gratis dengan semua batasan yang berlaku, kecuali pengguna melakukan perpanjangan atau pembelian paket baru.',
      ]),

      // 5. Subscription
      _buildSection('5. Ketentuan Berlangganan dan Pembayaran', [
        'Paket Premium CleanHNote tersedia dalam tiga pilihan durasi: 1 Bulan (Rp 29.000), 3 Bulan (Rp 79.000), dan 12 Bulan (Rp 290.000). Harga ini sudah termasuk semua fitur Premium dan dapat berubah sewaktu-waktu tanpa pemberitahuan sebelumnya.',
        'PENTING: Semua pembayaran yang telah dilakukan bersifat FINAL dan TIDAK DAPAT DIKEMBALIKAN (non-refundable) dalam kondisi apapun. Dengan melakukan pembayaran, Anda mengakui dan menyetujui bahwa tidak akan ada pengembalian dana, penukaran, atau pembatalan setelah transaksi selesai.',
        'Kebijakan non-refundable berlaku tanpa pengecualian, termasuk namun tidak terbatas pada situasi berikut: ketidakpuasan terhadap layanan atau fitur, perubahan pikiran setelah pembelian, kesalahan dalam memilih paket atau durasi, ketidakmampuan untuk menggunakan Aplikasi karena masalah teknis pada perangkat pengguna, penghapusan akun oleh pengguna sebelum masa berlaku berakhir, atau alasan pribadi lainnya.',
        'Tidak tersedia opsi pembatalan langganan atau pengembalian dana secara pro-rata. Akses Premium akan tetap aktif hingga akhir periode yang telah dibayar, setelah itu akan otomatis berakhir tanpa perpanjangan otomatis.',
        'Pembayaran dilakukan melalui metode yang tersedia pada waktu transaksi. Pengembang berhak untuk mengubah, menambah, atau menghapus metode pembayaran kapan saja tanpa pemberitahuan sebelumnya.',
        'Dengan melakukan pembayaran, Anda memberikan otorisasi penuh kepada pengembang atau penyedia layanan pembayaran pihak ketiga untuk memproses transaksi tersebut.',
        'Bukti pembayaran dan konfirmasi transaksi merupakan tanggung jawab pengguna untuk disimpan. Pengembang tidak bertanggung jawab atas kehilangan bukti pembayaran atau kegagalan sistem pembayaran pihak ketiga.',
        'Paket Premium tidak akan diperpanjang secara otomatis. Setelah masa berlaku berakhir, pengguna harus melakukan pembelian baru jika ingin melanjutkan akses Premium.',
      ]),

      // 6. User Responsibilities
      _buildSection('6. Tanggung Jawab Pengguna', [
        'Anda bertanggung jawab penuh atas semua konten yang Anda buat, unggah, atau bagikan melalui Aplikasi, termasuk judul tugas, deskripsi, foto, dan data lainnya.',
        'Anda setuju untuk menggunakan Aplikasi hanya untuk tujuan yang sah dan sesuai dengan hukum yang berlaku. Anda dilarang menggunakan Aplikasi untuk tujuan ilegal, penipuan, pelecehan, atau aktivitas yang merugikan pihak lain.',
        'Anda wajib memastikan bahwa semua informasi yang Anda masukkan ke dalam Aplikasi adalah akurat, benar, dan tidak menyesatkan. Penggunaan informasi palsu atau menyesatkan dapat mengakibatkan penangguhan atau penghapusan akun.',
        'Dalam konteks penggunaan fitur tim, Anda bertanggung jawab untuk mengelola anggota tim dengan bijaksana, memberikan tugas yang jelas dan adil, serta memverifikasi penyelesaian tugas dengan objektif.',
        'Untuk fitur unggah foto (before dan after), Anda wajib memastikan bahwa foto yang diunggah tidak mengandung konten yang melanggar hukum, tidak pantas, melanggar privasi orang lain, atau melanggar hak kekayaan intelektual pihak ketiga.',
        'Anda dilarang melakukan tindakan yang dapat mengganggu, merusak, atau membatasi fungsi Aplikasi, termasuk namun tidak terbatas pada: hacking, reverse engineering, penggunaan bot atau automasi yang tidak sah, atau upaya untuk mengakses data pengguna lain tanpa izin.',
        'Anda memahami dan menyetujui bahwa akurasi data tugas, ketepatan waktu penyelesaian, dan integritas informasi yang dimasukkan ke dalam Aplikasi merupakan tanggung jawab Anda sepenuhnya.',
      ]),

      // 7. Team Features
      _buildSection('7. Fitur Tim dan Kolaborasi', [
        'Fitur pembuatan tim hanya tersedia untuk pengguna Paket Premium. Setiap pengguna Premium hanya dapat membuat SATU (1) tim sebagai pemilik/owner, namun dapat bergabung dengan tim lain tanpa batas sebagai anggota.',
        'Pemilik tim memiliki kontrol penuh atas tim yang dibuatnya, termasuk kemampuan untuk: menambah atau mengeluarkan anggota, menugaskan tugas kepada anggota, melihat status penyelesaian tugas, mengakses analitik tim, dan menghapus tim.',
        'Undangan anggota tim dilakukan melalui kode QR unik yang dapat dibagikan kepada calon anggota. Setiap tim memiliki kode QR yang berbeda untuk keamanan.',
        'Anggota tim yang ditugaskan memiliki tanggung jawab untuk menyelesaikan tugas tepat waktu dan mengunggah foto bukti before (sebelum mengerjakan) dan after (setelah selesai) sebagai verifikasi penyelesaian tugas.',
        'Tugas tim yang tidak diselesaikan dalam jangka waktu yang ditentukan akan ditandai sebagai "Tertinggal" (Late) dan akan dihapus otomatis setelah 7 hari sejak deadline terlewati.',
        'Jika seorang anggota keluar dari tim atau dikeluarkan oleh pemilik tim, semua tugas yang ditugaskan kepada anggota tersebut akan tetap ada dan ditandai sebagai "Tertinggal" hingga dihapus otomatis.',
        'Pemilik tim bertanggung jawab atas manajemen tim yang efektif dan etis. Penyalahgunaan fitur tim dapat mengakibatkan penangguhan akses ke fitur tersebut.',
        'Analitik tim menyediakan informasi real-time tentang kinerja tim dan individu anggota, termasuk total tugas, tugas selesai, incomplete, late, dan rata-rata completion rate. Data ini dimaksudkan untuk meningkatkan produktivitas, bukan untuk tujuan yang merugikan.',
      ]),

      // 8. Data Management
      _buildSection('8. Manajemen dan Penyimpanan Data', [
        'CleanHNote menggunakan Firebase Firestore sebagai database utama untuk menyimpan data terstruktur seperti informasi pengguna, tugas pribadi, tugas tim, informasi tim, dan notifikasi. Semua data disinkronkan secara real-time ke cloud server.',
        'Untuk penyimpanan foto (fitur Premium), Aplikasi menggunakan layanan cloud storage aman. Foto yang diunggah akan dikompres secara otomatis untuk mengoptimalkan penggunaan ruang penyimpanan dan kecepatan akses tanpa mengurangi kualitas visual secara signifikan.',
        'Kebijakan Penghapusan Otomatis: (a) Tugas pribadi yang telah ditandai selesai akan dihapus otomatis setelah 7 hari, (b) Tugas tim (assignments) yang telah selesai akan dihapus otomatis setelah 7 hari, (c) Tugas tim yang melewati deadline (late/tertinggal) akan dihapus otomatis setelah 7 hari sejak deadline, (d) Notifikasi yang sudah dibaca akan dihapus otomatis setelah 7 hari.',
        'Penghapusan otomatis dimaksudkan untuk menjaga database tetap optimal dan mencegah akumulasi data yang tidak lagi relevan. Pengguna disarankan untuk menyimpan salinan data penting sebelum periode penghapusan otomatis.',
        'Pengembang menerapkan langkah-langkah keamanan yang wajar untuk melindungi data pengguna, termasuk enkripsi data saat transit dan autentikasi berbasis token. Namun, tidak ada sistem yang 100% aman, dan pengguna memahami risiko ini.',
        'Pengembang tidak akan membagikan, menjual, atau menyewakan data pribadi pengguna kepada pihak ketiga untuk tujuan komersial tanpa persetujuan eksplisit dari pengguna.',
        'Pengguna memiliki hak untuk mengakses, mengoreksi, atau menghapus data pribadi mereka dengan menghubungi pengembang. Penghapusan akun akan mengakibatkan penghapusan permanen semua data yang terkait dengan akun tersebut.',
        'Data yang telah dihapus (baik secara manual maupun otomatis) tidak dapat dipulihkan. Pengembang tidak menyimpan backup data pengguna untuk keperluan pemulihan.',
      ]),

      // 9. Notifications
      _buildSection('9. Notifikasi dan Pengingat', [
        'Aplikasi menggunakan sistem notifikasi push untuk mengirimkan pengingat tugas, pembaruan status tim, dan informasi penting lainnya kepada pengguna.',
        'Notifikasi dapat mencakup: pengingat tugas yang akan jatuh tempo, notifikasi tugas baru yang ditugaskan (untuk anggota tim), notifikasi penyelesaian tugas oleh anggota tim (untuk pemilik tim), pengingat tugas yang terlambat, dan pembaruan sistem atau fitur baru.',
        'Pengguna dapat mengatur preferensi notifikasi melalui pengaturan Aplikasi atau pengaturan sistem perangkat mereka. Namun, menonaktifkan notifikasi dapat mengurangi efektivitas penggunaan Aplikasi.',
        'Pengembang tidak bertanggung jawab jika notifikasi gagal diterima karena masalah koneksi internet, pengaturan perangkat, atau faktor eksternal lainnya di luar kendali Aplikasi.',
        'Notifikasi bersifat informatif dan dimaksudkan untuk membantu produktivitas. Pengguna tetap bertanggung jawab untuk memeriksa Aplikasi secara berkala untuk memastikan tidak ada tugas atau informasi penting yang terlewat.',
      ]),

      // 10. Intellectual Property
      _buildSection('10. Hak Kekayaan Intelektual', [
        'Semua hak kekayaan intelektual atas Aplikasi CleanHNote, termasuk namun tidak terbatas pada kode sumber, desain antarmuka, logo, nama merek, dan dokumentasi, adalah milik pengembang dan dilindungi oleh hukum hak cipta, merek dagang, dan hukum kekayaan intelektual lainnya yang berlaku.',
        'Anda diberikan lisensi terbatas, non-eksklusif, tidak dapat dialihkan, dan dapat dicabut untuk menggunakan Aplikasi sesuai dengan Ketentuan Layanan ini. Lisensi ini tidak memberikan Anda hak kepemilikan atas Aplikasi.',
        'Anda dilarang untuk: menyalin, memodifikasi, mendistribusikan, menjual, atau menyewakan bagian apapun dari Aplikasi; melakukan reverse engineering, dekompilasi, atau disassembly terhadap Aplikasi; menghapus atau mengubah pemberitahuan hak cipta atau merek dagang dari Aplikasi; atau menggunakan Aplikasi untuk membuat produk atau layanan yang bersaing.',
        'Konten yang Anda buat di dalam Aplikasi (seperti judul tugas, deskripsi, dan foto) tetap menjadi milik Anda. Namun, dengan mengunggah konten tersebut, Anda memberikan lisensi kepada pengembang untuk menyimpan, memproses, dan menampilkan konten tersebut dalam rangka penyediaan layanan Aplikasi.',
        'Jika Anda yakin bahwa konten di dalam Aplikasi melanggar hak kekayaan intelektual Anda, silakan hubungi pengembang dengan informasi yang memadai untuk investigasi.',
      ]),

      // 11. Limitation of Liability
      _buildSection('11. Batasan Tanggung Jawab', [
        'Aplikasi CleanHNote disediakan "SEBAGAIMANA ADANYA" (AS IS) dan "SEBAGAIMANA TERSEDIA" (AS AVAILABLE) tanpa jaminan dalam bentuk apapun, baik tersurat maupun tersirat, termasuk namun tidak terbatas pada jaminan tentang kelayakan untuk diperdagangkan, kesesuaian untuk tujuan tertentu, atau tidak adanya pelanggaran.',
        'Pengembang tidak menjamin bahwa Aplikasi akan berfungsi tanpa gangguan, bebas dari kesalahan, aman dari virus atau komponen berbahaya lainnya, atau bahwa semua bug atau error akan diperbaiki.',
        'Pengembang tidak bertanggung jawab atas kerugian atau kerusakan apapun yang timbul dari: penggunaan atau ketidakmampuan untuk menggunakan Aplikasi; kehilangan data atau kerusakan data; gangguan layanan atau downtime; kesalahan, kelalaian, atau ketidakakuratan konten; akses tidak sah ke server atau data pengguna; atau tindakan pihak ketiga.',
        'Dalam hal apapun, pengembang tidak akan bertanggung jawab atas kerugian tidak langsung, insidental, khusus, konsekuensial, atau kerugian yang bersifat hukuman, termasuk kehilangan keuntungan, pendapatan, data, atau goodwill, bahkan jika pengembang telah diberitahu tentang kemungkinan kerugian tersebut.',
        'Jika yurisdiksi Anda tidak mengizinkan pembatasan tanggung jawab tertentu, maka tanggung jawab pengembang akan dibatasi sejauh yang diizinkan oleh hukum.',
        'Total tanggung jawab pengembang kepada Anda atas semua klaim yang timbul dari atau terkait dengan Aplikasi tidak akan melebihi jumlah yang telah Anda bayarkan kepada pengembang (jika ada) dalam 12 bulan sebelum kejadian yang menimbulkan klaim.',
      ]),

      // 12. Termination
      _buildSection('12. Penghentian Layanan', [
        'Pengembang berhak untuk menangguhkan atau menghentikan akses Anda ke Aplikasi kapan saja, dengan atau tanpa pemberitahuan, dan dengan atau tanpa alasan, termasuk namun tidak terbatas pada pelanggaran Ketentuan Layanan ini.',
        'Pelanggaran yang dapat mengakibatkan penghentian akun termasuk: penggunaan Aplikasi untuk tujuan ilegal; pelanggaran hak kekayaan intelektual; pengunggahan konten yang melanggar, tidak pantas, atau berbahaya; upaya untuk mengakses data pengguna lain tanpa izin; manipulasi atau penyalahgunaan fitur Aplikasi; atau perilaku yang merugikan pengguna lain atau reputasi Aplikasi.',
        'Anda dapat menghentikan penggunaan Aplikasi kapan saja dengan menghapus akun Anda melalui pengaturan profil atau dengan menghubungi pengembang.',
        'Setelah penghentian akun, semua data Anda akan dihapus secara permanen dari server dalam waktu yang wajar. Data yang telah dihapus tidak dapat dipulihkan.',
        'Penghentian akun tidak memberikan hak untuk pengembalian dana atas pembayaran Premium yang telah dilakukan. Kebijakan non-refundable tetap berlaku.',
        'Ketentuan-ketentuan dalam Terms of Service yang secara alami harus tetap berlaku setelah penghentian (seperti ketentuan tentang hak kekayaan intelektual, batasan tanggung jawab, dan penyelesaian sengketa) akan tetap berlaku setelah penghentian.',
      ]),

      // 13. Changes to Terms
      _buildSection('13. Perubahan Ketentuan Layanan', [
        'Pengembang berhak untuk mengubah, memodifikasi, menambah, atau menghapus bagian apapun dari Ketentuan Layanan ini kapan saja tanpa pemberitahuan sebelumnya.',
        'Perubahan akan berlaku segera setelah dipublikasikan di dalam Aplikasi. Tanggal "Last Updated" di bagian atas dokumen ini akan diperbarui untuk mencerminkan tanggal perubahan terakhir.',
        'Penggunaan Aplikasi yang berkelanjutan setelah perubahan Ketentuan Layanan dianggap sebagai penerimaan Anda terhadap ketentuan yang telah diubah. Anda bertanggung jawab untuk memeriksa Ketentuan Layanan secara berkala.',
        'Jika Anda tidak menyetujui perubahan, Anda harus berhenti menggunakan Aplikasi dan dapat menghapus akun Anda.',
      ]),

      // 14. Contact Information
      _buildSection('14. Informasi Kontak', [
        'Jika Anda memiliki pertanyaan, komentar, keluhan, atau permintaan terkait Ketentuan Layanan ini atau Aplikasi CleanHNote, silakan hubungi pengembang melalui:',
        'Email: support@cleanhnote.com\n(atau melalui fitur kontak yang tersedia di dalam Aplikasi)',
        'Pengembang akan berusaha menanggapi pertanyaan Anda dalam waktu yang wajar, namun tidak menjamin waktu respons tertentu.',
      ]),

      // 15. Governing Law
      _buildSection('15. Hukum yang Berlaku', [
        'Ketentuan Layanan ini diatur oleh dan ditafsirkan sesuai dengan hukum Republik Indonesia, tanpa memperhatikan konflik prinsip hukum.',
        'Setiap sengketa yang timbul dari atau terkait dengan Ketentuan Layanan ini atau penggunaan Aplikasi akan diselesaikan melalui negosiasi yang baik. Jika negosiasi gagal, sengketa akan diselesaikan melalui pengadilan yang berwenang di Indonesia.',
      ]),
    ];
  }

  Widget _buildSection(String title, List<String> paragraphs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.indigo[900],
          ),
        ),
        const SizedBox(height: 12),
        ...paragraphs.map(
          (paragraph) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              paragraph,
              textAlign: TextAlign.justify,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Colors.grey[800],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
