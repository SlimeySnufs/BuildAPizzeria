# Viewport Frame Raycast Issues and Fixes

## Issues Found

### 1. **Wrong Target Parts for Raycasting**
- **Problem**: The code was registering placeholder parts for raycasting instead of the actual cloned items visible in the viewport
- **Location**: `StoreUI.luau` lines 249-254
- **Fix**: Changed `self.RegisterPurchaseChoice(i, part)` to `self.RegisterPurchaseChoice(i, item)` and hide the placeholder parts

### 2. **Incorrect Filter Configuration**
- **Problem**: The raycast filter was set to whitelist only the ViewportFrame itself, not the parts inside it
- **Location**: `StoreUI.luau` `ListenForMouseClick` function
- **Fix**: Changed filter to whitelist all BasePart descendants of the viewport that are visible (transparency < 1)

### 3. **Mouse Position Clamping Instead of Bounds Checking**
- **Problem**: Mouse coordinates were being clamped to viewport bounds, causing false hits when mouse was outside viewport
- **Location**: `StoreUI.luau` `ListenForMouseClick` function
- **Fix**: Added proper bounds checking to exit early if mouse is outside viewport

### 4. **Missing Camera Validation**
- **Problem**: No check if viewport camera exists before attempting raycast
- **Location**: `StoreUI.luau` `ListenForMouseClick` function
- **Fix**: Added camera existence check with warning

### 5. **Lack of Index Tracking**
- **Problem**: No way to track which store item index corresponds to which part
- **Location**: `StoreUI.luau` `RegisterPurchaseChoice` function
- **Fix**: Added `PartToIndex` mapping to track part-to-index relationships

## Code Changes Made

### 1. Fixed Part Registration
```lua
-- Before: Registered placeholder part
self.RegisterPurchaseChoice(i, part)

-- After: Register cloned item and hide placeholder
self.RegisterPurchaseChoice(i, item)
part.Transparency = 1
part.CanCollide = false
```

### 2. Improved Raycast Filter
```lua
-- Before: Only whitelisted viewport frame
raycastParams.FilterDescendantsInstances = {Viewport}

-- After: Whitelist all visible parts in viewport
local viewportParts = {}
for _, descendant in pairs(Viewport:GetDescendants()) do
    if descendant:IsA("BasePart") and descendant.Transparency < 1 then
        table.insert(viewportParts, descendant)
    end
end
raycastParams.FilterDescendantsInstances = viewportParts
```

### 3. Added Bounds Checking
```lua
-- Before: Clamped coordinates
localX = math.clamp(localX, 0, absSize.X)
localY = math.clamp(localY, 0, absSize.Y)

-- After: Early exit if outside bounds
if localX < 0 or localX > absSize.X or localY < 0 or localY > absSize.Y then
    return -- Mouse is outside viewport
end
```

### 4. Added Index Tracking
```lua
-- Store the index with the part for later reference
if not self.PartToIndex then
    self.PartToIndex = {}
end
self.PartToIndex[part] = index
```

## Debugging Features Added

- Mouse position logging within viewport bounds
- Ray origin and direction logging
- Part discovery logging (shows all parts found in viewport)
- Raycast result logging (hit/miss information)
- Target part validation logging

## Expected Behavior After Fixes

1. **Accurate Hit Detection**: Raycasts should now properly detect hits on the cloned store items in the viewport
2. **Bounds Awareness**: Clicks outside the viewport frame will be ignored
3. **Proper Item Selection**: Clicking on items will correctly set `self.CurrentItem` and track the store index
4. **Debug Information**: Console output will show detailed information about raycast attempts and results

## Testing Recommendations

1. Click on visible items in the store viewport - should see "Hit target part" messages
2. Click outside the viewport bounds - should see no raycast attempts
3. Click on empty areas within viewport - should see "Raycast missed all parts"
4. Verify that `self.CurrentItem` is properly set when clicking items
5. Check that item indices are correctly tracked and reported

## Potential Further Improvements

1. **Visual Feedback**: Add highlighting when items are selected
2. **Error Handling**: Add more robust error handling for edge cases
3. **Performance**: Consider caching viewport parts list instead of regenerating each click
4. **UI Responsiveness**: Add click feedback animations or sounds