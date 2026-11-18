program p
implicit none
character(2)::a(3),b(2)
a=['aa','bb','cc']
b=a([3,1])
if(any(b/=['cc','aa']))error stop 1
print '(i0)',1
end program
