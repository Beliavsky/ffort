program p
implicit none
logical::a(4)=[.true.,.false.,.false.,.true.]
character(3)::s(4)='abc'
where(a)
s='longer'
a=.false.
elsewhere
s='q'
end where
print *,s,a
end program
