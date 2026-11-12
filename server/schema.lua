KoraCryptoSchema = {
    {
        name = 'crypto',
        columns = {
            { name = 'crypto', type = 'varchar(50)', default = 'qbit' },
            { name = 'worth', type = 'int', default = 0 },
            { name = 'history', type = 'text', null = true, default = Kora.sql.NULL },
        },
        primary = { 'crypto' },
        seed = { rows = {
            { crypto = 'qbit', worth = 1000, history = '[{"NewWorth":1000,"PreviousWorth":1000}]' },
        } },
    },
}
