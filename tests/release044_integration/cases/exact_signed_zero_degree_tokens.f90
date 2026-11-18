program p
implicit none
real(8)::x(2)
integer::i
x=-0d0
print *,(asind(x(i)),i=1,2),cosd(0d0),acosd(1d0)
end program
