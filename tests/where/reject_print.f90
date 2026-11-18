program p
implicit none
integer::a(2)=0
where(a==0)
print *,a
end where
end program
