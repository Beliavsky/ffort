program p
implicit none
character(65536)::a,b
logical::x
integer::i
a="a"
b="z"
do i=1,32
x=lge(a,b)
enddo
print *,x
end program
