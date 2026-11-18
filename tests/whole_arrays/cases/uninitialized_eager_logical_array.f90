program probe
implicit none
logical :: a(2),b(2)
b=.false.
print *,99
b=b.and.a
end program probe
