import 'package:flutter/material.dart';

class WebNavigationItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final bool isComingSoon;
  final bool isMaintenance;
  final bool isBlocked;
  final bool isActive;
  final VoidCallback? onTap;

  const WebNavigationItem({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    this.isComingSoon = false,
    this.isMaintenance = false,
    this.isBlocked = false,
    this.isActive = true,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDisabled = isComingSoon || isMaintenance || isBlocked || !isActive;
    final opacity = (isMaintenance || isBlocked || !isActive) ? 0.5 : 1.0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isDisabled ? null : onTap,
          child: Opacity(
            opacity: opacity,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue[50] : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                // Removed border for cleaner look
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue[100] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: isSelected ? Colors.blue[600] : Colors.grey[600],
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.blue[800]
                                : Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            if (!isMaintenance &&
                                !isBlocked &&
                                isActive &&
                                !isComingSoon)
                              Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected
                                      ? Colors.blue[600]
                                      : Colors.grey[600],
                                ),
                              ),
                            if (isComingSoon) ...[
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange[100],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'SOON',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[700],
                                  ),
                                ),
                              ),
                            ],
                            if (isMaintenance) ...[
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.purple[100],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'MAINTENANCE',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple[700],
                                  ),
                                ),
                              ),
                            ],
                            if (isBlocked) ...[
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red[100],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'BLOCKED',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red[700],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!isDisabled && isSelected)
                    Icon(
                      Icons.chevron_right,
                      color: Colors.blue[600],
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
