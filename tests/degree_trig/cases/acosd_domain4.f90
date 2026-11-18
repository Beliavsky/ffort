program p
implicit none
real(4)::x
x=1.1_4
print *,"must not leak",acosd(x)
end program
