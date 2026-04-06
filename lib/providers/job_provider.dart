import 'package:flutter/foundation.dart';
import '../models/job_model.dart';

class JobProvider with ChangeNotifier {
  List<TeamRole> _teamRoles = [];
  
  List<TeamRole> get teamRoles => _teamRoles;
  int get teamRolesCount => _teamRoles.length;

  void addTeamRole(TeamRole role) {
    _teamRoles.add(role);
    notifyListeners();
    
    debugPrint('Team role added: ${role.roleName}');
    debugPrint('Total roles: ${_teamRoles.length}');
  }

  void updateTeamRole(int index, TeamRole updatedRole) {
    if (index >= 0 && index < _teamRoles.length) {
      final oldRole = _teamRoles[index];
      _teamRoles[index] = updatedRole;
      notifyListeners();
      
      debugPrint('Team role updated at index $index');
      debugPrint('Old: ${oldRole.roleName} → New: ${updatedRole.roleName}');
    } else {
      debugPrint('❌ Invalid index: $index (Total: ${_teamRoles.length})');
    }
  }

  void removeTeamRole(int index) {
    if (index >= 0 && index < _teamRoles.length) {
      final removedRole = _teamRoles[index];
      _teamRoles.removeAt(index);
      notifyListeners();
   
      debugPrint('Team role removed: ${removedRole.roleName}');
      debugPrint('Remaining roles: ${_teamRoles.length}');
    } else {
      debugPrint('Invalid index: $index (Total: ${_teamRoles.length})');
    }
  }

  TeamRole? getTeamRole(int index) {
    if (index >= 0 && index < _teamRoles.length) {
      return _teamRoles[index];
    }
    return null;
  }

  void clearTeamRoles() {
    _teamRoles.clear();
    notifyListeners();
    debugPrint(' All team roles cleared');
  }

  bool isRoleNameExists(String roleName, {int? excludeIndex}) {
    for (int i = 0; i < _teamRoles.length; i++) {
      if (i != excludeIndex && 
          _teamRoles[i].roleName.toLowerCase() == roleName.toLowerCase()) {
        return true;
      }
    }
    return false;
  }

  double getTotalBudget() {
    double total = 0;
    for (var role in _teamRoles) {
      String budgetStr = role.budget.replaceAll(RegExp(r'[^0-9]'), '');
      total += double.tryParse(budgetStr) ?? 0;
    }
    return total;
  }
}