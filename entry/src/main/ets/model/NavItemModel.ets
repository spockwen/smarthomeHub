export interface NavBadge {
  type: 'dot' | 'number';
  count?: number;
  maxCount?: number;
}

export interface NavItemModel {
  title: string;
  icon: string | Resource;
  selectedIcon?: string | Resource;
  badge?: NavBadge;
}