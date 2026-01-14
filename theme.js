// derlocke.net Theme Controller
// Based on Kiwi Blog - Compatible with both!

class ThemeController {
  constructor() {
    this.initializeElements();
    this.loadSavedThemes();
    this.setupEventListeners();
    this.setupDropdownMenu();
  }

  initializeElements() {
    this.contentSlider = document.getElementById('contentSlider');
    this.darkModeToggle = document.getElementById('darkModeToggle');
    this.menuToggle = document.querySelector('.menu-toggle');
    this.menuDropdown = document.querySelector('.menu-dropdown');
  }

  loadSavedThemes() {
    // Load saved themes or use derlocke defaults (dark mode, 50% intensity)
    const savedIntensity = localStorage.getItem('derlocke-colorIntensity') || '50';
    const savedDarkMode = localStorage.getItem('derlocke-darkMode');
    
    // Default to dark mode if not set
    const isDark = savedDarkMode === null ? true : savedDarkMode === 'true';

    // Apply slider values
    if (this.contentSlider) {
      this.contentSlider.value = savedIntensity;
    }

    // Apply themes
    this.updateColorIntensity(savedIntensity);
    this.updateDarkMode(isDark);
    this.updateDarkModeButton(isDark);
  }

  setupEventListeners() {
    // Color intensity slider - affects the 3 main colors (red, blue, yellow)
    if (this.contentSlider) {
      this.contentSlider.addEventListener('input', (e) => {
        this.updateColorIntensity(e.target.value);
        localStorage.setItem('derlocke-colorIntensity', e.target.value);
      });
    }

    // Dark mode toggle
    if (this.darkModeToggle) {
      this.darkModeToggle.addEventListener('click', () => {
        const currentMode = localStorage.getItem('derlocke-darkMode');
        const isDark = currentMode === null ? true : currentMode === 'true';
        const newMode = !isDark;
        this.updateDarkMode(newMode);
        this.updateDarkModeButton(newMode);
        localStorage.setItem('derlocke-darkMode', newMode.toString());
      });
    }

    // Smooth scroll for anchor links
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
      anchor.addEventListener('click', (e) => {
        const href = anchor.getAttribute('href');
        if (href && href !== '#') {
          const target = document.querySelector(href);
          if (target) {
            e.preventDefault();
            target.scrollIntoView({ behavior: 'smooth', block: 'start' });
            // Close dropdown menu after navigation
            this.closeMenu();
          }
        }
      });
    });

    // Handle links to index.html#id
    document.querySelectorAll('a[href^="index.html#"]').forEach(anchor => {
      anchor.addEventListener('click', (e) => {
        // Only handle if we're already on index.html
        if (window.location.pathname.endsWith('index.html') || 
            window.location.pathname.endsWith('/')) {
          const href = anchor.getAttribute('href');
          const hash = href.split('#')[1];
          const target = document.getElementById(hash);
          if (target) {
            e.preventDefault();
            target.scrollIntoView({ behavior: 'smooth', block: 'start' });
            this.closeMenu();
          }
        }
      });
    });
  }

  setupDropdownMenu() {
    if (this.menuToggle && this.menuDropdown) {
      // Toggle menu on click
      this.menuToggle.addEventListener('click', (e) => {
        e.stopPropagation();
        const isActive = this.menuDropdown.classList.contains('active');
        if (isActive) {
          this.closeMenu();
        } else {
          this.openMenu();
        }
      });

      // Close menu when clicking outside
      document.addEventListener('click', (e) => {
        if (!e.target.closest('.menu-container')) {
          this.closeMenu();
        }
      });

      // Close menu on escape key
      document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
          this.closeMenu();
        }
      });
    }
  }

  openMenu() {
    if (this.menuDropdown && this.menuToggle) {
      this.menuDropdown.classList.add('active');
      this.menuToggle.textContent = '✕';
      this.menuToggle.setAttribute('aria-expanded', 'true');
    }
  }

  closeMenu() {
    if (this.menuDropdown && this.menuToggle) {
      this.menuDropdown.classList.remove('active');
      this.menuToggle.textContent = '☰';
      this.menuToggle.setAttribute('aria-expanded', 'false');
    }
  }

  updateColorIntensity(intensity) {
    // This adjusts the saturation/brightness of the 3 main colors
    // The cursor color stays the same (cycles through red, blue, yellow)
    const root = document.documentElement;
    root.style.setProperty('--color-intensity', intensity);
  }

  updateDarkMode(isDark) {
    const root = document.documentElement;
    root.style.setProperty('--dark-mode', isDark ? '1' : '0');
    
    // Update meta theme-color for mobile browsers
    const metaTheme = document.querySelector('meta[name="theme-color"]');
    if (metaTheme) {
      metaTheme.setAttribute('content', isDark ? '#1a1a1a' : '#f5f5f5');
    }
  }

  updateDarkModeButton(isDark) {
    if (this.darkModeToggle) {
      this.darkModeToggle.textContent = isDark ? '☀️' : '🌙';
      this.darkModeToggle.setAttribute('title', isDark ? 'Switch to light mode' : 'Switch to dark mode');
    }
  }

  // Static method to reset themes to defaults
  static resetToDefaults() {
    localStorage.removeItem('derlocke-colorIntensity');
    localStorage.removeItem('derlocke-darkMode');
    location.reload();
  }
}

// Scroll progress indicator (optional enhancement)
function updateScrollProgress() {
  const scrollTop = document.documentElement.scrollTop || document.body.scrollTop;
  const scrollHeight = document.documentElement.scrollHeight - document.documentElement.clientHeight;
  const progress = (scrollTop / scrollHeight) * 100;
  
  const progressBar = document.querySelector('.scroll-progress');
  if (progressBar) {
    progressBar.style.width = progress + '%';
  }
}

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
  try {
    window.themeController = new ThemeController();
    
    // Initialize post navigation scroll spy
    initPostNavigation();
    
    // Initialize tag filtering
    initTagFilter();
    
    console.log('🖥️ derlocke.net theme loaded');
  } catch (error) {
    console.error('Theme initialization error:', error);
  }
});

// Post Navigation Scroll Spy
function initPostNavigation() {
  const postNav = document.getElementById('postNav');
  const postNavList = document.getElementById('postNavList');
  const postNavToggle = document.getElementById('postNavToggle');
  
  if (!postNav || !postNavList) return;
  
  const navItems = postNavList.querySelectorAll('.post-nav-item');
  if (navItems.length === 0) return;
  
  const blogEntries = document.querySelectorAll('.blogentry');
  if (blogEntries.length === 0) return;
  
  // Mobile toggle functionality
  if (postNavToggle) {
    postNavToggle.addEventListener('click', () => {
      const isOpen = postNav.classList.toggle('open');
      postNavToggle.textContent = isOpen ? '✕' : '📑';
    });
    
    // Close when clicking outside on mobile
    document.addEventListener('click', (e) => {
      if (window.innerWidth <= 1200 && 
          !e.target.closest('.post-nav') && 
          !e.target.closest('.post-nav-toggle')) {
        postNav.classList.remove('open');
        postNavToggle.textContent = '📑';
      }
    });
  }
  
  // Scroll spy - highlight current section
  const observerOptions = {
    root: null,
    rootMargin: '-80px 0px -60% 0px',
    threshold: 0
  };
  
  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        const id = entry.target.id;
        
        // Remove active from all
        navItems.forEach(item => item.classList.remove('active'));
        
        // Add active to current
        const activeItem = postNavList.querySelector(`[data-target="${id}"]`);
        if (activeItem) {
          activeItem.classList.add('active');
          
          // Scroll the nav list to show the active item
          const navRect = postNavList.getBoundingClientRect();
          const itemRect = activeItem.getBoundingClientRect();
          
          if (itemRect.top < navRect.top || itemRect.bottom > navRect.bottom) {
            activeItem.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
          }
        }
      }
    });
  }, observerOptions);
  
  // Observe all blog entries
  blogEntries.forEach(entry => observer.observe(entry));
  
  // Click handler for nav items
  navItems.forEach(item => {
    item.addEventListener('click', (e) => {
      e.preventDefault();
      const targetId = item.getAttribute('data-target');
      const target = document.getElementById(targetId);
      if (target) {
        target.scrollIntoView({ behavior: 'smooth', block: 'start' });
        // Close mobile nav after click
        if (window.innerWidth <= 1200 && postNavToggle) {
          postNav.classList.remove('open');
          postNavToggle.textContent = '📑';
        }
      }
    });
  });
}

// Expose reset function globally for debugging
window.resetTheme = ThemeController.resetToDefaults;

// Tag Filter Functionality
function initTagFilter() {
  const tagButtons = document.querySelectorAll('.tag-btn');
  const blogEntries = document.querySelectorAll('.blogentry[data-tags]');
  const postNavItems = document.querySelectorAll('.post-nav-item[data-tags]');
  const archivePostLinks = document.querySelectorAll('.archive-post-link[data-tags]');
  
  if (tagButtons.length === 0) return;
  
  // Load saved tag filter from localStorage
  const savedTag = localStorage.getItem('derlocke-activeTag') || 'all';
  
  // Apply saved filter on load
  applyTagFilter(savedTag, tagButtons, blogEntries, postNavItems, archivePostLinks);
  
  // Add click handlers to tag buttons
  tagButtons.forEach(btn => {
    btn.addEventListener('click', () => {
      const tag = btn.getAttribute('data-tag');
      applyTagFilter(tag, tagButtons, blogEntries, postNavItems, archivePostLinks);
      localStorage.setItem('derlocke-activeTag', tag);
    });
  });
}

function applyTagFilter(selectedTag, tagButtons, blogEntries, postNavItems, archivePostLinks) {
  // Update active button
  tagButtons.forEach(btn => {
    if (btn.getAttribute('data-tag') === selectedTag) {
      btn.classList.add('active');
    } else {
      btn.classList.remove('active');
    }
  });
  
  // Filter blog entries
  blogEntries.forEach(entry => {
    if (selectedTag === 'all') {
      entry.classList.remove('tag-hidden');
    } else {
      const entryTags = entry.getAttribute('data-tags') || '';
      const tagArray = entryTags.split(' ').map(t => t.trim()).filter(t => t);
      if (tagArray.includes(selectedTag)) {
        entry.classList.remove('tag-hidden');
      } else {
        entry.classList.add('tag-hidden');
      }
    }
  });
  
  // Filter post nav items to match
  postNavItems.forEach(item => {
    if (selectedTag === 'all') {
      item.classList.remove('tag-hidden');
    } else {
      const itemTags = item.getAttribute('data-tags') || '';
      const tagArray = itemTags.split(' ').map(t => t.trim()).filter(t => t);
      if (tagArray.includes(selectedTag)) {
        item.classList.remove('tag-hidden');
      } else {
        item.classList.add('tag-hidden');
      }
    }
  });
  
  // Filter archive post links
  archivePostLinks.forEach(link => {
    if (selectedTag === 'all') {
      link.classList.remove('tag-hidden');
    } else {
      const linkTags = link.getAttribute('data-tags') || '';
      const tagArray = linkTags.split(' ').map(t => t.trim()).filter(t => t);
      if (tagArray.includes(selectedTag)) {
        link.classList.remove('tag-hidden');
      } else {
        link.classList.add('tag-hidden');
      }
    }
  });
  
  // Update archive year counters to reflect visible posts
  const archiveYears = document.querySelectorAll('.archive-year');
  archiveYears.forEach(yearSection => {
    const visiblePosts = yearSection.querySelectorAll('.archive-post-link:not(.tag-hidden)');
    const postCountEl = yearSection.querySelector('.post-count');
    
    if (postCountEl) {
      const count = visiblePosts.length;
      postCountEl.textContent = count === 1 ? '1 post' : `${count} posts`;
    }
    
    // Hide entire year section if no visible posts
    if (visiblePosts.length === 0) {
      yearSection.classList.add('tag-hidden');
    } else {
      yearSection.classList.remove('tag-hidden');
    }
  });
}
