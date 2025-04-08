document.addEventListener('DOMContentLoaded', function() {
  const modal = document.getElementById('promptModal');
  const openButton = document.getElementById('openPromptModal');
  const closeButton = document.getElementById('closePromptModal');
  const submitButton = document.getElementById('submitPrompt');
  const promptText = document.getElementById('promptText');
  const responseContainer = document.getElementById('promptResponse');

  openButton?.addEventListener('click', () => {
    modal.classList.remove('hidden');
  });

  closeButton?.addEventListener('click', () => {
    modal.classList.add('hidden');
    promptText.value = '';
  });

  submitButton?.addEventListener('click', async () => {
    if (!promptText.value.trim()) {
      alert('Please enter your query');
      return;
    }

    try {
      const contractId = modal.getAttribute('data-contract-id');
      const response = await fetch(`/contracts/${contractId}/process_prompt`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ prompt_text: promptText.value })
      });

      const data = await response.json();
      
      if (data.success) {
        responseContainer.innerHTML = `
          <div class="mt-4 p-4 bg-white rounded-lg shadow">
            <h4 class="text-lg font-medium text-gray-900 mb-2">Analysis Result</h4>
            <div class="prose max-w-none">
              ${data.response}
            </div>
          </div>
        `;
        modal.classList.add('hidden');
        promptText.value = '';
      } else {
        alert(data.error || 'Failed to process prompt');
      }
    } catch (error) {
      console.error('Error:', error);
      alert('An error occurred while processing your request');
    }
  });
});