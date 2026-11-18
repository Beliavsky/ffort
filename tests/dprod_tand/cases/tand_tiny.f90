program p
implicit none
real::a(4)
real(8)::b(4)
a=[1.40129846e-45,-1.40129846e-45,tiny(1.0),-tiny(1.0)]
b=[4.9406564584124654d-324,-4.9406564584124654d-324,tiny(1d0),-tiny(1d0)]
print *,tand(a)
print *,tand(b)
end program
