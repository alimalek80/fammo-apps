import 'package:flutter/material.dart';
import '../services/pet_service.dart';
import '../services/auth_service.dart';
import 'pet_detail_page.dart';
import 'add_pet_page.dart';

class PetsListPage extends StatefulWidget {
  const PetsListPage({super.key});

  @override
  State<PetsListPage> createState() => _PetsListPageState();
}

class _PetsListPageState extends State<PetsListPage> {
  final PetService _petService = PetService();
  List<Pet> _pets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    setState(() => _isLoading = true);
    
    final pets = await _petService.getUserPets();
    
    setState(() {
      _pets = pets;
      _isLoading = false;
    });
  }

  Future<void> _confirmDeletePet(Pet pet) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete Pet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          content: Text(
            'Are you sure you want to delete ${pet.name}? This action cannot be undone.',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF7F8C8D),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF7F8C8D),
                  fontSize: 14,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.1),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      await _deletePet(pet);
    }
  }

  Future<void> _deletePet(Pet pet) async {
    try {
      setState(() => _isLoading = true);
      
      final success = await _petService.deletePet(pet.id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${pet.name} has been deleted'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        
        // Refresh the list
        _loadPets();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to delete pet. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: const Text(
          'My Pets',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: _pets.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: _pets.length,
                            itemBuilder: (context, index) {
                              return _buildPetCard(_pets[index]);
                            },
                          ),
                  ),
                  // Add Pet Button
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: InkWell(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddPetPage(),
                          ),
                        );
                        
                        if (result == true && mounted) {
                          _loadPets();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF26B5A4),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF26B5A4).withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Add Pet',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Text('🐾', style: TextStyle(fontSize: 60)),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Pets Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Add your first pet to start tracking their health and nutrition',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF7F8C8D),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetCard(Pet pet) {
    return InkWell(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PetDetailPage(pet: pet),
          ),
        );
        
        if (result == true && mounted) {
          _loadPets();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Pet Image/Avatar
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5F3),
                    borderRadius: BorderRadius.circular(12),
                    image: pet.image != null
                        ? DecorationImage(
                            image: NetworkImage(pet.image!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: pet.image == null
                      ? Center(
                          child: Text(
                            pet.petIcon,
                            style: const TextStyle(fontSize: 48),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                // Pet Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              pet.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: pet.petType == 2 
                                  ? Colors.purple.withOpacity(0.1)
                                  : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(pet.petIcon, style: const TextStyle(fontSize: 14)),
                                const SizedBox(width: 4),
                                Text(
                                  pet.displayPetType,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: pet.petType == 2 
                                        ? Colors.purple
                                        : Colors.orange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        pet.displayBreed,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF7F8C8D),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.cake, size: 14, color: Color(0xFF7F8C8D)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              pet.displayAge.isNotEmpty ? pet.displayAge : 'Age unknown',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF7F8C8D),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (pet.weight != null) ...[
                            const Text(' • ', style: TextStyle(color: Color(0xFF7F8C8D), fontSize: 12)),
                            const Icon(Icons.monitor_weight, size: 14, color: Color(0xFF7F8C8D)),
                            const SizedBox(width: 4),
                            Text(
                              '${pet.weight} kg',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF7F8C8D),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Chevron icon
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF7F8C8D),
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Action buttons row
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      // Navigate to Nutrition Plan
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5F3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.restaurant, size: 16, color: Color(0xFF26B5A4)),
                          SizedBox(width: 6),
                          Text(
                            'Nutrition Plan',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF26B5A4),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      // Navigate to Health Report
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.pink.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.favorite, size: 16, color: Colors.pink.shade400),
                          const SizedBox(width: 6),
                          Text(
                            'Health Report',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.pink.shade400,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Second row: Chat and Delete buttons
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      // Navigate to AI Chat
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 16, color: Colors.amber.shade700),
                          const SizedBox(width: 6),
                          Text(
                            'Chat with AI',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Delete button
                InkWell(
                  onTap: () => _confirmDeletePet(pet),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Delete',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
