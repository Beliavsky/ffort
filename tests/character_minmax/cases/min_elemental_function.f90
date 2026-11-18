program p
write(*,"(a)")f(["aa","zz"])
contains
pure elemental function f(a) result(b)
character(2),intent(in)::a
character(3)::b
b=min(a,"bbb")
end function
end program
