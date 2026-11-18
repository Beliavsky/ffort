implicit none
character(4), parameter :: x(2)=['abcd','wxyz']
character(2), parameter :: y=x(2)(2:3)
print '(a)',y,x(1)(3:)
end
