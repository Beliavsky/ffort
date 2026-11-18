program p
implicit none
real(8)::x
x=1.1_8
print *,"must not leak",acosd(x)
end program
