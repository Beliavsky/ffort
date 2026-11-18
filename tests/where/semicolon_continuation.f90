program p
implicit none
integer::a(3)=[1,2,3]
where(a> &
 1); a=a*2; elsewhere; a=0; end where
print *,a
end program
