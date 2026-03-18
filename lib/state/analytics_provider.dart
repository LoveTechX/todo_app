// Private helper to set the focus score, clamping to non-negative
void _setFocusScore(int value) {
    focusScore = value < 0 ? 0 : value;
}

// Assuming there's existing code where 'focusScore' is assigned after loading daily events
void loadDailyEvents() {
    // ... existing logic ...
    // If events are empty
    if (events.isEmpty) {
        _setFocusScore(0);
    } else {
        // process events and set focus score accordingly
        _setFocusScore(calculatedValue); // replace 'calculatedValue' with actual logic
    }
}

void recordEvent(Event event) {
    // ... existing logic ...
    // When an event is recorded, set focusScore
    _setFocusScore(currentFocusScore + delta); // replace 'currentFocusScore + delta' with actual logic
}
