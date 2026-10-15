// Step 2: Render the cards from CLUBS.
const clubGrid = document.getElementById("clubGrid");

function escapeHtml(value) {
  const div = document.createElement("div");
  div.textContent = value;
  return div.innerHTML;
}

function clubCardHTML(club) {
  const image = club.image
    ? `<img src="${escapeHtml(club.image)}" alt="" class="club-banner-image" loading="lazy" />`
    : "";

  return `
    <article class="club-card" data-club-id="${escapeHtml(club.id)}">
      <div class="club-image-box">
        ${image}
        <span class="club-category-pill ${escapeHtml(club.categoryClass)}">${escapeHtml(club.category)}</span>
      </div>
      <div class="club-info-body">
        <h2 class="club-title">${escapeHtml(club.name)}</h2>
        <p class="club-tagline">${escapeHtml(club.tagline)}</p>
        <div class="club-footer-row">
          <span class="club-members-count">${club.members} members</span>
          <button type="button" class="join-club-button">Join club</button>
        </div>
      </div>
    </article>`;
}

clubGrid.innerHTML = CLUBS.map(clubCardHTML).join("");
