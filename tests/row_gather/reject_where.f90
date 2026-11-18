program p
implicit none
integer::a(3,2),b(2,2)
logical::mask(2,2)
mask=.false.
where(mask) b=a([1,2],:)
end program
