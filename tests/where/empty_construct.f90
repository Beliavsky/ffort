program p
implicit none
integer::a(2)=[1,2]
where(a>0)
elsewhere(a<0)
elsewhere
end where
print *,a
end program
