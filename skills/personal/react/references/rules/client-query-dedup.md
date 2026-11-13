---
title: Fetch Through the Query Cache
impact: MEDIUM-HIGH
impactDescription: automatic deduplication
tags: client, react-query, deduplication, data-fetching
---

## Fetch Through the Query Cache

react-query deduplicates, caches, and revalidates requests across every component that uses the same query key.

**Incorrect (no deduplication, each instance fetches):**

```tsx
function UserList() {
  const [users, setUsers] = useState([]);
  useEffect(() => {
    fetch("/api/users")
      .then((r) => r.json())
      .then(setUsers);
  }, []);
}
```

**Correct (multiple instances share one request):**

```tsx
import { useQuery } from "@tanstack/react-query";

function UserList() {
  const { data: users = [] } = useQuery({
    queryKey: ["users"],
    queryFn: fetchUsers,
  });
}
```

**For immutable data:**

```tsx
function StaticContent() {
  const { data } = useQuery({
    queryKey: ["config"],
    queryFn: fetchConfig,
    staleTime: Infinity,
  });
}
```

**For mutations (invalidate the key so every reader refetches once):**

```tsx
import { useMutation, useQueryClient } from "@tanstack/react-query";

function UpdateButton() {
  const queryClient = useQueryClient();
  const update = useMutation({
    mutationFn: updateUser,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["users"] }),
  });
  return <button onClick={() => update.mutate()}>Update</button>;
}
```

Reference: [https://tanstack.com/query/latest](https://tanstack.com/query/latest)
