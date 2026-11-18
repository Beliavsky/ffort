implicit none
character(0) :: z(1)
character(3) :: x(1) = ['abc']
z(1)(:)=''
x(1)(3:2)='Q'
print '(i0)',len(z(1)(:)),len(x(1)(3:2))
print '(a)',x
end
