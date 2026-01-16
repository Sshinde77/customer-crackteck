import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Feedback\'s',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: 6,
        itemBuilder: (context, index) {
          return _buildFeedbackCard(index);
        },
      ),
    );
  }

  Widget _buildFeedbackCard(int index) {
    // Sample data for variety
    final feedbacks = [
      {
        'user': 'Caover92',
        'date': '22 Jul',
        'text': 'KaiB was amazing with our cats!! ✨✨✨ This was our first time using a pet-sitting service, so we were naturally quite anxious. We took a chance on Kai and completely lucked out!We booked Kai to come twice a day for three days.',
        'rating': 5,
      },
      {
        'user': 'KaiB',
        'date': '22 Jul',
        'text': 'KaiB was phenomenal with our dog, Max! We were first-time users of a pet-sitting service and were quite nervous. Kai\'s professionalism and warmth immediately put us at ease.',
        'rating': 5,
      },
      {
        'user': 'PetParent7',
        'date': '22 Jul',
        'text': 'KaiB was phenomenal with our dog, Max! We were first-time users of a pet-sitting service and were quite nervous. Kai\'s professionalism and warmth immediately put us at ease.',
        'rating': 5,
      },
      {
        'user': 'HappyPetMom',
        'date': '22 Jul',
        'text': 'Absolutely fantastic service from Kai! As first-time Pet Backer users, we were unsure what to expect. Kai\'s attentive care and detailed updates put us at ease.',
        'rating': 5,
      },
      {
        'user': 'FurBabyFan',
        'date': '22 Jul',
        'text': 'KaiB did an outstanding job looking after our bunny, Thumper! ✨✨✨ We were worried about leaving him alone, but Kai\'s attentive care made all the difference.',
        'rating': 5,
      },
      {
        'user': 'Caover92',
        'date': '22 Jul',
        'text': 'KaiB was amazing with our cats!! ✨✨✨ This was our first time using a pet-sitting service, so we were naturally quite anxious. We took a chance on Kai and completely lucked out!We booked Kai to come twice a day for three days.',
        'rating': 5,
      },
    ];

    final feedback = feedbacks[index % feedbacks.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    feedback['user'] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.circle, size: 4, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    feedback['date'] as String,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    Icons.star,
                    color: i < (feedback['rating'] as int) ? Colors.amber : Colors.grey.shade300,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            feedback['text'] as String,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
