GoogleMock currently lets users wrap mocks in NiceMock/StrictMock/NaggyMock to control how uninteresting calls are handled, but there is no supported way for code that only has a pointer/reference to a mock object to query which mode it is in. This becomes a problem when a mock produces other mocks (e.g., a factory mock that returns a child mock) and wants to propagate the same “niceness/strictness” to the returned mock instance.

Add public query functions on `::testing::Mock` so that given a mock object pointer they can tell whether the object is currently treated as a NiceMock, StrictMock, or NaggyMock.

Required API:
- `static bool ::testing::Mock::IsNice(void* mock_obj)`
- `static bool ::testing::Mock::IsStrict(void* mock_obj)`
- `static bool ::testing::Mock::IsNaggy(void* mock_obj)`

Behavior requirements:
- When a mock object is wrapped as `NiceMock<T>`, `Mock::IsNice(&obj)` must return true, and `Mock::IsStrict(&obj)`/`Mock::IsNaggy(&obj)` must return false.
- When wrapped as `StrictMock<T>`, `Mock::IsStrict(&obj)` must return true, and the others false.
- When wrapped as `NaggyMock<T>`, `Mock::IsNaggy(&obj)` must return true, and the others false.
- For an unwrapped mock object (default behavior), `Mock::IsNaggy(&obj)` should be true and `Mock::IsNice(&obj)`/`Mock::IsStrict(&obj)` false (i.e., default reaction corresponds to “naggy”).
- Querying should be safe to call at any time after construction (including inside default actions used by `ON_CALL`/`WillByDefault`), and it must reflect the mode that controls uninteresting-call behavior for that object.

Example usage that should work:
```cpp
FactoryMock() {
  using namespace ::testing;
  ON_CALL(*this, GetChild()).WillByDefault(Invoke([this]() {
    if (Mock::IsNice(this)) return std::make_shared<NiceMock<ChildMock>>();
    if (Mock::IsStrict(this)) return std::make_shared<StrictMock<ChildMock>>();
    return std::make_shared<ChildMock>();
  }));
}
```

The new API must compile for typical mock types and integrate with existing NiceMock/StrictMock/NaggyMock behavior so that the returned booleans match the actual uninteresting-call reaction the framework applies to the object.