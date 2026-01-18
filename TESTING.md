# Testing Checklist

## Guest Mode
- [ ] Can play without account
- [ ] Progress saves to IndexedDB
- [ ] Can upgrade to account (data merges)

## Authentication
- [ ] Parent signup works
- [ ] Parent login works
- [ ] Password reset works
- [ ] Session persists across refresh
- [ ] Logout clears session

## Family Management
- [ ] Can add children (up to 5)
- [ ] Child PIN login works
- [ ] PIN reset works
- [ ] Can edit child name
- [ ] Can remove child (with confirmation)

## Gameplay
- [ ] Puzzles generate correctly at all 10 difficulties
- [ ] Start/end cells always connected
- [ ] Path selection works (tap cells)
- [ ] Timer works
- [ ] Lives system works (standard mode)
- [ ] Hidden mode works

## Parent Dashboard
- [ ] Shows all children
- [ ] Weekly stats calculate correctly
- [ ] Child detail screen loads
- [ ] Activity history shows

## Puzzle Maker
- [ ] Difficulty selector works
- [ ] Puzzle count slider works
- [ ] Generate creates puzzles
- [ ] Preview displays correctly
- [ ] Print/PDF works
- [ ] Answer key included when selected

## PWA
- [ ] Install prompt shows (after engagement)
- [ ] App installs correctly
- [ ] Works offline (gameplay)
- [ ] Update prompt shows for new versions

## Responsive Design
- [ ] Mobile (320px - 480px)
- [ ] Tablet (768px - 1024px)
- [ ] Desktop (1024px+)
- [ ] Landscape orientation

## Performance
- [ ] Initial load < 3 seconds
- [ ] Puzzle generation < 100ms
- [ ] Smooth animations (60fps)
