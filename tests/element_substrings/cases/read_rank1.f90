implicit none
character(5) :: x(-1:1) = ['one  ','two  ','three']
print '(a)',x(1)(2:4),x(-1)(:3),x(0)(3:),x(1)(:)
end
