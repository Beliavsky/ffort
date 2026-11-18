program main
implicit none
character(2)::x(3)
character(3)::y(3)
x=['aa','cc','b ']
y=max(x([3,1,2]),'bb ')
print '(a)',y
end program
