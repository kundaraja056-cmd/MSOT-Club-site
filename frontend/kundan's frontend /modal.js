// Step 3: Modal behaviour. One click handler for all cards (no inline onclick).
const modal = document.getElementById("clubModal");
const modalTitle = document.getElementById("modalTitle");
const modalTagline = document.getElementById("modalTagline");
const modalMembers = document.getElementById("modalMembers");
let activeClub = null;

function openClubModal(id) {
  activeClub = CLUBS.find((club) => club.id === id);
  if (!activeClub) return;
  modalTitle.textContent = activeClub.name;
  modalTagline.textContent = activeClub.tagline;
  modalMembers.textContent = `${activeClub.members} members`;
  modal.showModal();
}

clubGrid.addEventListener("click", (event) => {
  const card = event.target.closest(".club-card");
  if (card) openClubModal(card.dataset.clubId);
});

document.getElementById("modalClose").addEventListener("click", () => modal.close());

document.getElementById("modalJoin").addEventListener("click", () => {
  // TODO: send the join request to your backend here.
  console.log("Join requested:", activeClub.id);
  modal.close();
});

// Close when clicking the backdrop.
modal.addEventListener("click", (event) => {
  if (event.target === modal) modal.close();
});
