const fixedNames = [
  'Sb.',
  'Gw.',
  'Db.',
  'Dm.',
  'Sg.',
  'Ag.',
  'Fb.',
  'Al.',
  'Gb.',
  'Dw.',
  'Gl.',
  'Ds.',
];

bool isFixedName(String name) => fixedNames.contains(name.trim());
