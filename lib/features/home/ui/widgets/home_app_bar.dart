import 'package:finance_tracker_app_001/features/home/logic/home_cubit.dart';
import 'package:finance_tracker_app_001/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theming/app_colors.dart';
import 'financial_reports_dialog.dart';
import 'package:intl/intl.dart';
import 'package:finance_tracker_app_001/features/settings/logic/backup_cubit.dart';
import 'package:finance_tracker_app_001/features/settings/logic/backup_state.dart';

class HomeAppBar extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  const HomeAppBar({super.key, required this.scaffoldKey});

  @override
  State<HomeAppBar> createState() => _HomeAppBarState();
}

class _HomeAppBarState extends State<HomeAppBar> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'personal_data':
        context.push(AppRoutes.settings);
        break;
      case 'local_backup_restore':
        _showFeatureDialog(
          title: 'نسخ احتياطي محلي',
          message: 'تم حفظ نسخة احتياطية محلية لقاعدة البيانات بنجاح على ذاكرة الجهاز الداخلية.',
          icon: Icons.storage_rounded,
          color: Colors.green,
        );
        break;
      case 'gdrive_backup_restore':
      case 'gdrive_sync':
        _showGDriveDialog();
        break;
      case 'send_database':
        _showFeatureDialog(
          title: 'إرسال قاعدة البيانات',
          message: 'هل تريد مشاركة وإرسال نسخة احتياطية من قاعدة البيانات الحالية؟',
          icon: Icons.share_rounded,
          color: Colors.blue,
          onConfirm: () {
            Share.share('نسخة قاعدة بيانات تطبيق فيت تراك المالية المحدثة.');
          },
        );
        break;
      case 'share_app':
        Share.share('قم بتحميل تطبيق فيت تراك لإدارة وتتبع مصاريفك وحساباتك المالية بكل سهولة!');
        break;
      case 'rate_app':
        _showRatingDialog();
        break;
      case 'our_apps':
        _showFeatureDialog(
          title: 'تطبيقاتنا على المتجر',
          message: 'تفضل بزيارة صفحتنا على متجر التطبيقات لمشاهدة جميع برامجنا وأدواتنا المفيدة.',
          icon: Icons.store_mall_directory_rounded,
          color: Colors.purple,
        );
        break;
      case 'privacy_policy':
        _showPrivacyPolicyDialog();
        break;
    }
  }

  void _showFeatureDialog({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
    VoidCallback? onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق', style: TextStyle(color: Colors.grey)),
          ),
          if (onConfirm != null)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('موافق', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  void _showUploadNameDialog(BuildContext context, BackupCubit cubit) {
    final textController = TextEditingController(
      text: 'backup_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}',
    );
    showDialog(
      context: context,
      builder: (nameDialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تسمية النسخة الاحتياطية', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            labelText: 'اسم النسخة',
            hintText: 'أدخل اسماً للنسخة الاحتياطية',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(nameDialogContext),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final name = textController.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(nameDialogContext);
                cubit.uploadBackup(name);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('رفع'),
          ),
        ],
      ),
    );
  }

  void _showConfirmRestoreDialog(BuildContext context, String backupName, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (confirmContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 10),
            Text('تأكيد الاستعادة', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'تحذير: سيتم استبدال جميع بيانات التطبيق الحالية بالبيانات الموجودة في النسخة "$backupName". هل أنت متأكد من المتابعة؟',
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(confirmContext),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(confirmContext);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.debtor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('موافق (استبدال)'),
          ),
        ],
      ),
    );
  }

  void _showGDriveDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return BlocConsumer<BackupCubit, BackupState>(
          listener: (context, state) {
            if (state is BackupSyncSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'تمت عملية المزامنة بنجاح!',
                    textAlign: TextAlign.center,
                  ),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
              Navigator.pop(dialogContext);
            }
          },
          builder: (context, state) {
            final backupCubit = context.read<BackupCubit>();
            
            Widget content;
            List<Widget> actions = [];
            
            if (state is BackupInitial) {
              content = Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_rounded, size: 64, color: AppColors.iconSecondary),
                  const SizedBox(height: 16),
                  const Text(
                    'يرجى مصادقة حساب جوجل (Gmail) للتمكن من حفظ واستعادة بياناتك سحابياً على Google Drive الخاص بك.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              );
              actions = [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton.icon(
                  onPressed: () => backupCubit.signInWithGoogle(),
                  icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                  label: const Text('تسجيل الدخول بجوجل'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ];
            } else if (state is BackupLoading) {
              content = const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 24),
                  Text(
                    'جاري الاتصال والعمل... يرجى الانتظار.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              );
            } else if (state is BackupAuthenticationSuccess || state is BackupSyncSuccess) {
              final email = state is BackupAuthenticationSuccess 
                  ? state.userEmail 
                  : (state as BackupSyncSuccess).userEmail;
                  
              final lastSync = state is BackupSyncSuccess ? state.lastSyncedAt : null;
              
              content = Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_done_rounded, size: 64, color: Colors.green),
                  const SizedBox(height: 16),
                  Text(
                    'متصل بـ: $email',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  if (lastSync != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'آخر عملية مزامنة: ${DateFormat('yyyy-MM-dd HH:mm').format(lastSync)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _showUploadNameDialog(dialogContext, backupCubit),
                        icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                        label: const Text('رفع نسخة سحابية', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green, 
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => backupCubit.loadBackupsList(),
                        icon: const Icon(Icons.cloud_download_rounded, size: 18),
                        label: const Text('استعادة النسخة', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary, 
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ],
              );
              
              actions = [
                TextButton(
                  onPressed: () => backupCubit.signOut(),
                  child: const Text('تسجيل الخروج', style: TextStyle(color: AppColors.debtor)),
                ),
                const SizedBox(width: 40),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('إغلاق', style: TextStyle(color: Colors.grey)),
                ),
              ];
            } else if (state is BackupListLoaded) {
              final backups = state.backups;
              
              content = SizedBox(
                width: double.maxFinite,
                height: 250,
                child: backups.isEmpty
                    ? const Center(
                        child: Text(
                          'لا توجد نسخ احتياطية محفوظة على هذا الحساب.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: backups.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final backup = backups[index];
                          final name = backup['name'] ?? 'نسخة احتياطية';
                          final id = backup['id'] as String;
                          final rawTime = backup['createdTime'] as String?;
                          String formattedTime = '';
                          if (rawTime != null) {
                            try {
                              final parsedTime = DateTime.parse(rawTime).toLocal();
                              formattedTime = DateFormat('yyyy-MM-dd HH:mm').format(parsedTime);
                            } catch (_) {
                              formattedTime = rawTime;
                            }
                          }
                          
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              formattedTime.isNotEmpty ? formattedTime : 'غير محدد',
                              style: const TextStyle(color: Colors.grey, fontSize: 11),
                            ),
                            trailing: ElevatedButton(
                              onPressed: () {
                                _showConfirmRestoreDialog(dialogContext, name, () {
                                  backupCubit.downloadBackup(id);
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('استعادة', style: TextStyle(fontSize: 11)),
                            ),
                          );
                        },
                      ),
              );

              actions = [
                TextButton(
                  onPressed: () => backupCubit.resetToAuthenticated(),
                  child: const Text('رجوع', style: TextStyle(color: AppColors.primary)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('إغلاق', style: TextStyle(color: Colors.grey)),
                ),
              ];
            } else if (state is BackupFailure) {
              content = Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 64, color: AppColors.debtor),
                  const SizedBox(height: 16),
                  Text(
                    state.errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.debtor, fontSize: 14, height: 1.5),
                  ),
                ],
              );
              
              actions = [
                TextButton(
                  onPressed: () => backupCubit.silentSignIn(),
                  child: const Text('إعادة المحاولة', style: TextStyle(color: AppColors.primary)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('إغلاق', style: TextStyle(color: Colors.grey)),
                ),
              ];
            } else {
              content = const SizedBox.shrink();
            }
            
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('النسخ الاحتياطي سحابياً', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: content,
              ),
              actions: actions,
            );
          },
        );
      },
    );
  }

  void _showRatingDialog() {
    int selectedStars = 0;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Center(
            child: Text('تقييم التطبيق', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('ما هو تقييمك لتجربتك مع تطبيق فيت تراك؟', textAlign: TextAlign.center, style: TextStyle(fontSize: 14)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  return IconButton(
                    icon: Icon(
                      starIndex <= selectedStars ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: Colors.amber,
                      size: 36,
                    ),
                    onPressed: () {
                      setDialogState(() {
                        selectedStars = starIndex;
                      });
                    },
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: selectedStars == 0
                  ? null
                  : () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('شكراً لتقييمك الرائع! نعمل دائماً لتقديم أفضل تجربة.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('إرسال التقييم', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.privacy_tip_rounded, color: AppColors.primary, size: 28),
            SizedBox(width: 10),
            Text('سياسة الخصوصية', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'نحن في فيت تراك ملتزمون بحماية خصوصيتك وبياناتك المالية بشكل كامل. كافة العمليات الحسابية وتفاصيل الحسابات يتم معالجتها وحفظها محلياً على جهازك باستخدام قواعد بيانات مشفرة ولا يتم مشاركتها مع أي طرف ثالث دون إذنك.',
                style: TextStyle(fontSize: 13, height: 1.5),
              ),
              SizedBox(height: 12),
              Text(
                'المزامنة السحابية:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              SizedBox(height: 4),
              Text(
                'عند تفعيل المزامنة السحابية عبر جوجل درايف، يتم حفظ نسخة مشفرة من قاعدة البيانات على حسابك الشخصي لضمان إمكانية استرجاعها عند تغيير الهاتف.',
                style: TextStyle(fontSize: 12, height: 1.4, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('موافق', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems(BuildContext context) {
    return [
      // Account Group
      const PopupMenuItem<String>(
        value: 'personal_data',
        child: Row(
          children: [
            Icon(Icons.person_rounded, color: AppColors.iconSecondary),
            SizedBox(width: 12),
            Text('البيانات الشخصية'),
          ],
        ),
      ),
      const PopupMenuDivider(),
      // Data Management Group
      const PopupMenuItem<String>(
        value: 'local_backup_restore',
        child: Row(
          children: [
            Icon(Icons.storage_rounded, color: AppColors.iconSecondary),
            SizedBox(width: 12),
            Text('حفظ وإسترجاع البيانات من الجهاز'),
          ],
        ),
      ),
      const PopupMenuItem<String>(
        value: 'gdrive_backup_restore',
        child: Row(
          children: [
            Icon(Icons.cloud_download_rounded, color: AppColors.iconSecondary),
            SizedBox(width: 12),
            Text('حفظ/إسترجاع البيانات من جوجل درايف'),
          ],
        ),
      ),
      const PopupMenuItem<String>(
        value: 'gdrive_sync',
        child: Row(
          children: [
            Icon(Icons.sync_rounded, color: AppColors.iconSecondary),
            SizedBox(width: 12),
            Text('مزامنة البيانات على جوجل درايف'),
          ],
        ),
      ),
      const PopupMenuDivider(),
      // Application Actions Group
      const PopupMenuItem<String>(
        value: 'send_database',
        child: Row(
          children: [
            Icon(Icons.share_rounded, color: AppColors.iconSecondary),
            SizedBox(width: 12),
            Text('إرسال قاعدة البيانات'),
          ],
        ),
      ),
      const PopupMenuItem<String>(
        value: 'share_app',
        child: Row(
          children: [
            Icon(Icons.share_rounded, color: AppColors.iconSecondary),
            SizedBox(width: 12),
            Text('مشاركة التطبيق'),
          ],
        ),
      ),
      const PopupMenuItem<String>(
        value: 'rate_app',
        child: Row(
          children: [
            Icon(Icons.star_rounded, color: AppColors.iconSecondary),
            SizedBox(width: 12),
            Text('قيم التطبيق'),
          ],
        ),
      ),
      const PopupMenuItem<String>(
        value: 'our_apps',
        child: Row(
          children: [
            Icon(Icons.store_rounded, color: AppColors.iconSecondary),
            SizedBox(width: 12),
            Text('تطبيقاتنا على المتجر'),
          ],
        ),
      ),
      const PopupMenuItem<String>(
        value: 'privacy_policy',
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: AppColors.iconSecondary),
            SizedBox(width: 12),
            Text('سياسة الخصوصية'),
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isSearching) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            setState(() => _isSearching = false);
            _searchController.clear();
            context.read<HomeCubit>().refresh();
          },
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          onChanged: (q) => context.read<HomeCubit>().searchAccounts(q),
          decoration: InputDecoration(
            hintText: '${l10n.search}...',
            border: InputBorder.none,
            fillColor: Colors.transparent,
          ),
        ),
      );
    }

    return AppBar(
      leading: PopupMenuButton<String>(
        icon: const Icon(Icons.menu_rounded),
        onSelected: (val) => _handleMenuSelection(val),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        itemBuilder: (context) => _buildMenuItems(context),
      ),
      title: Text(l10n.general),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded),
          tooltip: l10n.search,
          onPressed: () => setState(() => _isSearching = true),
        ),
        IconButton(
          icon: Image.asset(
            'assets/icons/export_icon.png',
            width: 24,
            height: 24,
          ),
          tooltip: l10n.exportData,
          onPressed: () => FinancialReportsDialog.show(context),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}


