implicit none
character(6) :: x(2) = ['abcdef','uvwxyz']
x(1)(2:5)=x(1)(1:4)
x(2)(:2)='Q'
x(2)(5:)='1234'
print '(a)',x
end
