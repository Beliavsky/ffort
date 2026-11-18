program rankthree
implicit none
character(3) :: aa(2,1,2)
aa='abc'
aa(2,1,2)='xyz'
print *,aa(1,1,1),aa(2,1,2)
end program rankthree
