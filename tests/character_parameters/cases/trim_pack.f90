implicit none
character(*),parameter::a(1)=pack([trim("ab "),trim("cd  ")],[.false.,.true.])
character(*),parameter::b(0)=pack([trim("ab "),trim("cd  ")],.false.)
print '(a)',a
print *,size(b)
end
