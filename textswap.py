def findBestPosition(newText: str, draftText: str) -> int:
    n = len(newText)
    
    for i in range(n):
        # Convert to list to swap characters
        new_list = list(newText)
        print(new_list)
        draft_list = list(draftText)

        # Swap characters at index i
        new_list[i], draft_list[i] = draft_list[i], new_list[i]

        # Compare after swap
        if ''.join(new_list) < ''.join(draft_list):
            return i + 1  # Return 1-based index

    return -1  # No valid swap found

print(findBestPosition('hellp','hello'))