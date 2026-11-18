program probe
implicit none
logical :: a(3)
a(1)=.true.
a(2)=.false.
a(3)=a(1).and..not.a(2)
print *,a(1),a(2),a(3)
end program probe
