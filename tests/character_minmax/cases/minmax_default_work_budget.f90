program p
implicit none
character(65536)::a,b
integer::j
a=repeat("x",65536)
b=a
do j=1,20
a=min(a,b)
enddo
print *,"must not leak"
end program
